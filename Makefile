.PHONY:
	import-server-cert \
	create-client-cert \
	revoke-client-cert \
	export-vpn-config

# Folder containing pki files generated by easy-rsa.
EASYRSA_PKI     ?= pki
CA_CRT_NAME     ?= ca
SERVER_CRT_NAME ?= server
PROJECT_NAME     = go-api-template
CLIENT_CRT_NAME  = ""

import-server-cert:
	aws acm import-certificate                                              \
		--certificate fileb://$(EASYRSA_PKI)/issued/$(SERVER_CRT_NAME).crt  \
		--private-key fileb://$(EASYRSA_PKI)/private/$(SERVER_CRT_NAME).key \
		--certificate-chain fileb://$(EASYRSA_PKI)/$(CA_CRT_NAME).crt       \
		--tags Key=type,Value=server

create-client-cert:
	easyrsa --batch build-client-full $(CLIENT_CRT_NAME) nopass

revoke-client-cert:
	easyrsa --batch revoke $(CLIENT_CRT_NAME)
	easyrsa gen-crl
	aws ec2 import-client-vpn-client-certificate-revocation-list                                                                   \
		--client-vpn-endpoint-id $(shell aws ec2 describe-client-vpn-endpoints | yq '.ClientVpnEndpoints.[0].ClientVpnEndpointId') \
		--certificate-revocation-list file://$(EASYRSA_PKI)/crl.pem

export-vpn-config:
	scripts/export-vpn-config.sh                      \
		$(PROJECT_NAME)                               \
		$(EASYRSA_PKI)/issued/$(CLIENT_CRT_NAME).crt  \
		$(EASYRSA_PKI)/private/$(CLIENT_CRT_NAME).key \
		> $(CLIENT_CRT_NAME).ovpn
