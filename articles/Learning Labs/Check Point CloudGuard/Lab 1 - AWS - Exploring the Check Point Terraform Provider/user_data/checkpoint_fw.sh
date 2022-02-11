#!/bin/bash

# DO NOT USE THIS SCRIPT FOR CLOUDGUARD GWLB AMIs

set -e

exec 1>/var/log/aws-user-data.log 2>&1

# Update for local time-zone offset
echo "Start Time:    $(date +%T)"

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

echo "$(date +%T)   Setting hostname to ${cp_fw_hostname}"
clish -c "set hostname ${cp_fw_hostname}" -s

echo "$(date +%T)   Setting admin & expert password hashes"
touch temp_hash
chmod 600 temp_hash
cpopenssl passwd -1 ${cp_passwd} > temp_hash
pwd_hash=$(cat temp_hash)
clish -c "set user admin password-hash $pwd_hash" -s
clish -c "set expert-password-hash $pwd_hash" -s
rm temp_hash

echo "$(date +%T)   Setting admin shell to ${cp_shell}"
clish -c "set user admin shell ${cp_shell}" -s

echo "$(date +%T)   Starting First Time Wizard"
blink_config -s "install_security_gw=true&install_ppak=true&gateway_cluster_member=false&ftw_sic_key='${cp_sic}'&upload_info=false&download_info=false&admin_hash='$pwd_hash'"
unset pwd_hash

echo -e "\n $(date +%T)   All config completed, rebooting for clean start..."
shutdown -r now