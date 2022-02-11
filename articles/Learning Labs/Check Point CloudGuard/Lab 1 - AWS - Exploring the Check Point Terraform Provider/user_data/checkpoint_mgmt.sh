#!/bin/bash

set -e

exec 1>/var/log/aws-user-data.log 2>&1

echo -e "\nStarting user data...\n"
echo "$(date +%T)   Updating cloud-version file"
template="management"
cv_path="/etc/cloud-version"
if test -f $cv_path; then
  echo "template_name: $template" >> $cv_path
  echo "template_version: 20220131" >> $cv_path
  echo "template_type: terraform" >> $cv_path
fi

cv_json_path="/etc/cloud-version.json"
cv_json_path_tmp="/etc/cloud-version-tmp.json"

if test -f $cv_json_path; then
   cat $cv_json_path | jq '.template_name = "'"$template"'"' | jq '.template_version = "20210309"' | jq '.template_type = "terraform"' > $cv_json_path_tmp
   mv $cv_json_path_tmp $cv_json_path
fi


echo "$(date +%T)   Obtaining configuration lock"
clish -c "lock database override" || true


echo "Configuring NTP Server & Time Zone"
clish -c "set ntp server primary ${ntp_primary} version 4" -s
clish -c "set ntp active on" -s
clish -c "set timezone ${cp_timezone}"


echo "$(date +%T)   Setting hostname to ${cp_mgmt_hostname}"
clish -c "set hostname ${cp_mgmt_hostname}" -s


echo "$(date +%T)   Setting admin & expert password hashes"
touch temp_hash
chmod 600 temp_hash
cpopenssl passwd -1 ${cp_passwd} > temp_hash
pwd_hash=$(cat temp_hash)
clish -c "set user admin password-hash $pwd_hash" -s
clish -c "set expert-password-hash $pwd_hash" -s
unset pwd_hash
rm temp_hash


echo "$(date +%T)   Setting admin shell to ${cp_shell}"
clish -c "set user admin shell ${cp_shell}" -s


echo "$(date +%T)   Starting First Time Wizard"
# Install fails if you try to split this string.
config_system -s 'install_security_gw=false&install_security_managment=true&mgmt_gui_clients_radio=any&install_mgmt_primary=true&install_mgmt_secondary=false&mgmt_admin_radio=gaia_admin&ftw_sic_key="Tester2022!"&download_info=false&upload_info=false'

is_config_successful=$?

if test $is_config_successful -ne 0; then
    echo "$(date +%T)    System configuration unsuccessful, manual configuration required."
    exit 1
else
    echo "$(date +%T)    System configuration successful!"
fi

# [OPTIONAL CONFIG]
# Uncomment below line if EC2 instance size for Check Point Management Server has < 8GB RAM
# clish -c "api start"

# This takes approx. 3-5 minutes
echo "$(date +%T)   Waiting for API to start..."
until mgmt_cli -r true discard; do
    sleep 30
done


# Default: API access restricted to local host only
echo "$(date +%T)   API is UP; modifying to permit public access..."
mgmt_cli -r true set api-settings accepted-api-calls-from "All IP addresses" --domain 'System Data'
clish -c "api restart"
echo "$(date +%T)   API has been restarted; public access possible"


echo "$(date +%T)   Modifying Global Properties"
dbedit_cmds="modify properties firewall_properties icmpenable true\nmodify properties firewall_properties fw_allow_out_of_state_tcp 1\nquit -update_all" 
echo -e $dbedit_cmds > dbedit_config
dbedit -local -f dbedit_config


echo "$(date +%T)   Verifying Global Properties status..."
echo "print properties firewall_properties" > query
icmp_value=$(dbedit -local -f query | grep icmpenable:)
tcp_value=$(dbedit -local -f query | grep fw_allow_out_of_state_tcp:)
icmp_expected="true"
tcp_expected="1"

# Check if returned value contains expected value
if [[ "$icmp_value" == *"$icmp_expected"* ]]; then

  if [[ "$tcp_value" == *"$tcp_expected"* ]]; then
    echo "$(date +%T)   Global properties have been updated."
    rm query
    rm dbedit_config
  fi

else
  echo "$(date +%T)   Global properties were not updated successfully."
fi


echo "$(date +%T)  Changing the default Cleanup rule to permit everything"
mgmt_cli -r true set access-rule \
  name "Cleanup rule" \
  layer "Network" \
  action "Accept" \
  track.type "Log"

echo "$(date +%T)  Initiating trusted SIC communication with cloudguard-fw"
mgmt_cli -r true add simple-gateway \
  name "${cp_fw_hostname}" \
  comments "Managed by Terraform" \
  ipv4-address ${cp_fw_private_ip} \
  one-time-password "${cp_sic}" \
  version "R80.40" \
  os-name "Gaia" \
  color "red" \
  firewall true \
  interfaces.1.name "eth0" \
    interfaces.1.ipv4-address "${cp_fw_private_ip}" \
    interfaces.1.ipv4-mask-length ${cp_fw_ipv4_mask_length} \
    interfaces.1.anti-spoofing false \
    interfaces.1.topology "EXTERNAL" \
  interfaces.2.name "eth1" \
    interfaces.2.ipv4-address "${cp_fw_protected_ip}" \
    interfaces.2.ipv4-mask-length ${cp_fw_ipv4_mask_length} \
    interfaces.2.anti-spoofing false \
    interfaces.2.topology "internal" \
    interfaces.2.topology-settings.interface-leads-to-dmz false \
    interfaces.2.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask"  

echo "$(date +%T)  Installing access policy on ${cp_fw_hostname}"
mgmt_cli -r true install-policy \
  policy-package "standard" \
  targets "${cp_fw_hostname}" \
  access true \
  qos false \
  threat-prevention false
  
echo -e "\n $(date +%T)   Configuration Completed!"