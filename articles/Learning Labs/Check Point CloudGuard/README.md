# [ether-net] Learning Labs: Check Point CloudGuard

## Overview

This repository contains learning labs associated with Check Point's CloudGuard virtual appliance.

<br />

## Disclaimer

These labs are refined versions of private environments I have been using to study Check Point CloudGuard deployments within cloud service providers.

I do not consider myself an expert in these technologies, so if you have any improvement suggestions please don't hesitate to submit a pull request for me to review.

<br />

## General Pre-Requisites

Most labs assume the following:
* Exposure to Check Point Security products, specifically the Security Management Server and Gateway Appliances with the Firewall blade installed
* Foundational cloud networking knowledge for the cloud service provider the lab relates to
* Terraform Associate / RHCE levels of knowledge with Terraform and Ansible respectively.
* Foundational working knowledge of Linux is beneficial, specifically bash scripting

<br />

## Cost Disclaimer

These labs do not always leverage resources that are "free tier" eligible.

Cost estimates and breakdowns are supplied in every lab in USD, however note that you, and you alone, are **fully responsible** for:
* All costs incurred with labs
* Verifying cost accuracies with each lab are accurate per the cloud service provider(s) current charge rates
* Ensuring that Terraform plans destroy all provisioned resources and "reset" the cloud service provider environment to its initial state

<br />

## Labs

<br />

| Lab  | CSP | Short Description | Difficulty | Total Cost Estimate (USD) | Status |
|------|-----|-------------------|------------|---------------------------|--------|
| 1    | AWS | Exploring the Check Point Terraform Provider | Intermediate | `$1.663 p/h` + `$0.05 p/GB from EC2 to Internet` | Partially Complete - pending lab guide (ETA Feb 28 2022) |
| 2    | AWS | Architecture Pattern #1 - CloudGuard per VPC | Intermediate | - | In Development  |
| 3    | AWS | Architecture Pattern #2 - Single Hub: Single AZ, Single Appliance | Intermediate | - | In Development |
| 4    | AWS | Architecture Pattern #3 - Single Hub: Multi-AZ, Multi-Appliance with Resource Scaling Groups | Intermediate | - |  In Development |
| 5    | AWS | Architecture Pattern #4 - Dual Hub: Simple Ingress/Egress Traffic Flow Separation | Advanced | - | Concept |
| 6    | AWS | Architecture Pattern #5 - Dual Hub: Advanced Ingress/Egress Traffic Flow Separation | Advanced | - | Concept |
| 7    | AWS | Architecture Pattern #6 - Triple Hub: Separating North/South and East/West Traffic Flows | Advanced | - | Concept |
| 8    | AWS | Architecture Pattern #7 - Exploring Aviatrix FireNet with CheckPoint CloudGuard | Advanced | - | Research |