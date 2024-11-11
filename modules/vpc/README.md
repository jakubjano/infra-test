# VPC
Virtual Private Cloud is a fundamental and highly customizable networking service. It allows you to create isolated and
private network environments within the cloud, providing a high degree of control over your network architecture, security,
and connectivity.

Our VPC contains two availability zones (never deploy a single zone!) - `us-east-1a` and `us-east-1b`, since our default
region is `us-east-1`. CIDR is set to `10.0.0.0/16`, which should be more than enough for this simple infrastructure. VPC contains
3 subnet types with 6 subnets in total:
- Public subnets: `10.0.1.0/24`, `10.0.2.0/24`
- Database subnets: `10.0.3.0/24`, `10.0.4.0/24`
- Private subnets: `10.0.5.0/24`, `10.0.6.0/24`

Maybe you wonder, why there are separate subnets for a database. First to understand, the database subnets are actually private
subnets. By splitting up your subnets this way, helps to enforce a greater level of security. Logical grouping of similar
resources also helps you to maintain an ease of management across your infrastructure. It's a similar thought process,
your house has more than one room, as each room serves a different purpose.

The last thing you have probably already noticed is that we deploy NAT gateway. Without this resource, everything located
in our private subnets wouldn't have access to the internet.

⚠️ AWS accounts are limited to 5 elastic IP addresses. Two of them are associated with NAT gateways so you have only
3 left. It's not a problem since we deploy one infrastructure environment per
AWS [account](https://docs.aws.amazon.com/accounts/latest/reference/welcome-multiple-accounts.html) within an AWS organization.
I don't recommend deploying development, staging and production environment to a single AWS account.
