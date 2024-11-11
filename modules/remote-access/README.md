# Remote access
This module offers two different ways how to access private cloud components - bastion host and VPN.

## Bastion Host
A bastion host, often referred to as a jump host or a jump server, is a specially configured server that is used as an
intermediary or gateway to access and manage other servers or resources within a VPC. The primary purpose of a bastion
host is to enhance security by controlling and restricting direct access to sensitive or critical systems while allowing
authorized users to access them indirectly through the bastion host.

If you think of the VPN for accessing the database, you're on track! The reason why you want a bastion host is to access
the database. Why don't we use VPN by default, and as the only option? It's simply because of the price. But if money is not
a problem (it's not an issue for most of our client projects), of course, you can go with the standard [VPN](#vpn). Bastion
host is deployed as an EC2 instance with instance type `t2.micro`, which is free, and [ami](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
`ami-0eb01a520e67f7f20`, which is the Amazon Linux 2023 machine image and is also free. Free VPN, feels so good!

ED25519 key pair is associated with the instance. You are unable to access the machine without this PEM key. The second
thing required for connecting to the machine itself is the security group. There is a `bastion_host` security group.
The ingress rule allows only those connections via port 22. As can be seen in the ingress of the security group, all IP addresses
are allowed. Security recommendation says you should limit this range. Although the main security aspect is the private key,
if you have a public static IP, don't hesitate to put it in the ingress to automatically deny all connections, which may come
from an attacker. The egress rule interconnects the EC2 instance with the database. The rule allows outcoming connections
only to a database, nowhere else (there is no other resource in the template you should want to connect to). So keep in
mind that you need to update egress rules in case there is another resource in the private network you would like to have
access to.

### Deployment
Deployment of bastion is driven by an environment's config var file. There is a boolean variable `create_bastion_host`
that is set to `false` by default. Changing it to `true` and running
```shell
terraform apply -var-file=terraform.tfvars
```

is everything you need to do. After the successful deployment, you see output variables, where you can find:
```shell
bastion_host_dns_name = "ec2-18-208-253-137.compute-1.amazonaws.com"
bastion_host_private_key_openssh = <sensitive>
database_cluster_endpoint = "go-api-template-postgres.cluster-chb4ficdk9sr.us-east-1.rds.amazonaws.com"
```

Let's try the bastion host and configure database access in your IDE. Database DSN can be found in the parameter store.
It won't be working since you need to set up an SSH tunnel to the bastion host. To be able to do that, you need PEM key:
```shell
terraform output -raw bastion_host_private_key_openssh >bastion-host-key.pem
```

⚠️ Run `chmod 600 bastion-host-key.pem` and add a new line at the end of the `bastion-host-key.pem` ¯\\\_(ツ)\_/¯

The next step is to run the SSH tunnel:
```shell
ssh -i bastion-host-key.pem -L 5432:go-api-template-postgres.cluster-chb4ficdk9sr.us-east-1.rds.amazonaws.com:5432 ec2-user@ec2-18-208-253-137.compute-1.amazonaws.com.compute-1.amazonaws.com -N -f
```

Don't forget to change the database name and EC2 host according to your needs. It starts the SSH tunnel in the background, so now
your IDE should give you green. It's also recommended to change the local port because it's highly probable that you have
already running some Postgres instance on your local machine. In the case of the Go API template, there is reserved port 5432 for
any local database, 5433 for the development database running within the docker compose, and 5434 for the database running in
integration tests. It's also possible to set up an SSH tunnel in your IDE. ⚠️ In this case, don't forget to set up a staging
environment with the write lock so you won't accidentally break the whole environment by unprofessional interventions in
the database.

## VPN
A virtual private network (VPN) is a mechanism for creating a secure connection between a computing device and a computer
network, or between two networks, using an insecure communication medium such as the public Internet.

🤔 As you will see in the following sections, VPN is not as easy to setup as bastion host but has much better security,
scalability and maintainability. Don't be afraid that your developer experience will suffer - almost all steps are required
only during initial configuration/deployment. When you complete the setup, the maintenance is quite seamless.

The consensus in the backend department is that we should strive to use VPN as our default solution but not recklessly.
We should always take in mind the client's situation and decide based on all possible factors because the pricing of VPN
is not very friendly:
- Client VPN endpoint association $0.10 per hour -> approx. $72 monthly per subnet.
- Client VPN connection $0.05 per hour. Keep in mind that when the connection lasts let's say only 5 minutes, you are charged
  the whole hour anyway. It's better to keep the VPN connection running for a few hours than constantly starting and ending
  connections when you need to access the database to debug something.
- Data transfers out are free up to 100 GB so that is a negligible fee.

Let's take a real example of the VPN price. Our typical client project has 3 environments (dev, stg, prod). There are two
backend engineers and one QA who have access to the database via VPN. Each environment has two public subnets, which means
two VPN endpoint associations per environment -> $144. Let's say each client uses a VPN for 20 hours per month (as we already
know, an hour is charged even when the connection is alive for a single minute). It means $3 for all three people. In the
case of three environments, it's $441 just for the VPN. I see big bad here.

Now you understand why automatically choosing a VPN doesn't have to be always the right choice, especially for projects that
don't make any money yet and the VPN price would make up most of the client's AWS spending. My opinion is that different
project stages require different approaches. That's why my recommendation is to start with the bastion host that is free
and easy to use. When a project scope and team size increase, I would transparently communicate with the client our needs,
price, and all aspects of using a VPN.

### EasyRSA
Before we deploy a VPN, there is an important prerequisite to know. [EasyRSA](https://github.com/OpenVPN/easy-rsa) is a CLI
utility to build and manage a PKI CA ([public key infrastructure](https://en.wikipedia.org/wiki/Public_key_infrastructure)).
In laymen's terms, this means to create a root certificate authority and request and sign certificates, including
intermediate CAs and certificate revocation lists (CRL). There is a `pki` directory in the project root with already
generated CA, server certificate, and one client certificate (tomas-kocman). Public certificates are located in directory
`issued`, whereas associated private keys are stored in directory `private`. CA lies in the `pki` root directory. The
`pki` directory serves as an EasyRSA environment. That's why I recommend to set `EASYRSA_PKI` variable:
```shell
export EASYRSA_PKI=pki
```

If you didn't set this env variable, EasyRSA would operate within the default environment in the installation location
(/opt/homebrew/etc/pki in my case).

⚠️ Delete this folder and create a new `pki` environment. The existing `pki` directory in the master branch is just as
an example how it should look like and what is the final state when you create your own `pki` with your own `CA` and `server`
certificate.

### Deployment
Now let's deploy this uneaten beast. Deploying of VPN is not and in principle cannot be a fully automated process. You need
to create a CA with a distinguished name and passphrase. There is an option to leave this with default values but I would recommend
deploying this security-critical component with a portion of true love. As you already know from the previous section, the creation
of the `pki` environment is the first step to managing our certificates. First, set the `EASYRSA_PKI` env variable (don't
forget to delete the existing `pki` directory, we need to create a new one for security reasons):
```shell
export EASYRSA_PKI=pki
```

Initialize `pki`:
```shell
easyrsa init-pki
```

A fresh `pki` directory has been created. Now create our root CA that will be later used for creating other certificates.
You will be asked to enter a distinguished name. Feel free to use the name of your project. In my case, it's go-api-template:
```shell
easyrsa build-ca nopass
```

`ca.crt` plus a bunch of other files have been created. As another step, create a server certificate:
```shell
easyrsa build-server-full server nopass
```

The server certificate with the name `server` has been created. Let's prepare your client certificate:
```shell
easyrsa build-client-full tomas-kocman nopass
```

The client certificate with the name you provided has been created. Public certificates are in the `issued` directory,
whereas their associated private keys are in the `private` directory. In the same way as with bastion host, deployment
of VPN is driven by an environment's config var file. There is a boolean variable `create_vpn` that is set to `false`
by default. Changing it to `true` is the first half of what you need to do. The second half is to set the variable
`vpn_server_certificate_arn`. To to deploy a VPN, ACM (certificate manager) has to contain the server certificate.
We already generated one, so just import it to the ACM by hitting the Makefile command (don't forget on `aws sso login`):
```shell
make import-server-cert
```

⚠️ If you changed file names and your CA is not named `ca.crt` and your server certificate is not named `server.crt`, just check
Makefile variables and set them according to your needs.

At this point, you can get server certificate ARN from the AWS console and set the `vpn_server_certificate_arn` variable.
Now just hitting
```shell
terraform apply -var-file=terraform.tfvars
```
is everything you need to do. After the successful deployment (make a coffee/tea cause you will wait at least 10 minutes for
creating network associations), you have the client VPN endpoint up and running.

### Client
From the client perspective, you need to import VPN configuration into the VPN client (Linux has sufficient support for
VPN, whereas on MacOS, I recommend OpenVPN client). There are two ways to create a VPN client configuration:
- Export config in AWS console and modify it accordingly.
- Second, recommended way, is to use the Makefile command `make export-vpn-config CLIENT_CRT_NAME=tomas-kocman`.

I strongly recommend the second approach because after downloading the client config, the remote URL has to be modified with
an extra subdomain, and client `<cert>` and `<key>` sections have to be added. The Makefile command does everything for you.
Just import the newly created `ovpn` file into the OpenVPN client and you go. You, as an infra admin, have everything set up,
meaning VPN deployment and fully running client connection with OpenVPN client. But what about other team members? It's not a very
maintainable approach to let each team member generate their client certificates and push them into the repo. For that
purpose, I recommend using GitHub CI (they are described in the top level [README](../../README.md)). Every team member can
run the manual CI workflow `create-vpn-client-cert` either on the GitHub website or via the `gh` command:
```shell
gh workflow run create-vpn-client-cert --field client_name=jozko-dlouhy
```

This workflow creates the client certificate using the Makefile command `make create-client-cert` and all generated files
(public certificate, private key, request, ...) are then pushed into the repo (master branch) automatically by a workflow.
After the workflow successfully completes, and after the pulling changes, the team member can run `make export-vpn-config CLIENT_CRT_NAME=jozko-dlouhy`
and import the resulting VPN configuration into the OpenVPN client. There is a huge potential for improvement by creating a Slack
bot that would call the workflow, wait for the completion, run the Makefile command, and send the resulting VPN configuration
to a team member.

Regarding security, an integral part of VPN maintenance is the revoking of certificates. When a team member, let's say a
QA is fired or has been transferred to another project, you have to revoke his certificate to be sure he won't have access
to the cloud components within your project. For this operation is prepared CI workflow `revoke-vpn-client-cert` that can be run
either on the GitHub website or via the `gh` command:
```shell
gh workflow run revoke-vpn-client-cert --field client_name=jozko-dlouhy
```

This workflow runs `make revoke-client-cert CLIENT_CRT_NAME=jozko-dlouhy`, which does certificate revocation, and the changes
are then pushed into the repo (master branch) automatically by a workflow. The main part of the revocation process is
creating/updating of a CRL file. Workflow imports the CRL file to the client VPN endpoint in AWS, so poor Jozko Dlouhy loses
his VPN access practically instantly.

☝🏻 Although everything is possible via your local terminal, I recommend maintaining the certificates using CI workflows.

### Configuration
Follows a description of important or interesting configuration details:
- Same as with the bastion host, an important aspect of the VPN is the security group. The `vpn` security group accepts incoming
  connections on port 443 and UDP protocol. There is no restriction regarding IP addresses. The main security aspect here is
  the client certificate, not the IP address in the external network. The egress rule is set the same as in bastion
  host - traffic only to the database is allowed.
- VPN is deployed with observability in mind. VPN is configured with CloudWatch log group and log stream. That means you
  can check in CloudWatch logs how team members use the VPN. Based on their VPN usage patterns, you as an infra admin can
  propose for example keeping the connection up for the whole working day instead of constantly creating a new connection
  when there is a repeatable need to debug something during the day. It both saves pennies and is convenient for a VPN user.
- VPN cannot share the same network as VPC public networks, that's why `10.1.0.0/16` CIDR block is used. DNS server is
  `10.0.0.2`, which is AWS's default DNS server no matter what infra configuration you have. Session timeout hours are set
  8 hours, which is the minimum possible value. You don't have to be afraid that when you forget to shut down the VPN
  connection, your favorite personal videos you are used to watching every night will go through the AWS VPN. VPN is configured
  with a split tunnel parameter, so only traffic with destination IP addresses belonging to the VPC network range will be
  routed to the VPN.
