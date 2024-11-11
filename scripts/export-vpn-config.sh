#!/bin/bash
# This script is intended to be run by Makefile in CI.
set -e

if [ -z "$1" ]
then
  echo "Project name is not set" && exit 1
fi

if [ -z "$2" ]
then
  echo "Certificate path is not set" && exit 1
fi

if [ -z "$3" ]
then
  echo "Private key path is not set" && exit 1
fi

project_name="$1"
certificate=$(sed -n '/-----BEGIN CERTIFICATE-----/,$p' < "$2")
private_key=$(cat "$3")

# Export VPN config.
vpn_endpoint_id=$(aws ec2 describe-client-vpn-endpoints | yq '.ClientVpnEndpoints.[0].ClientVpnEndpointId')
vpn_client_config=$(aws ec2 export-client-vpn-client-configuration --client-vpn-endpoint-id "$vpn_endpoint_id" --output text)
# Modify remote address with project subdomain.
vpn_client_config=${vpn_client_config/remote cvpn/remote $project_name.cvpn}
# Append client certificate
vpn_client_config=$vpn_client_config"\n\n<cert>\n$certificate\n</cert>"
vpn_client_config=$vpn_client_config"\n\n<key>\n$private_key\n</key>\n"

echo "$vpn_client_config"
