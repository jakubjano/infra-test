# Common
This module serves as a common base, which is useful for every environment.

Deployed resources:
- `OIDC role`: Allows GitHub actions to plan/deploy.
- `LogReader IAM group`: Allows users within this group to read CloudWatch logs. This is useful because we create AWS
	accounts for frontend developers and QA at every project so they can check logs of our applications when needed. When
  it comes to creating of AWS accounts for your colleagues, prefer SSO accounts with appropriate role access to other
  accounts. If it isn't possible (for example because AWS root accounts is not in your hands), the only option is to
  create IAM users in particular AWS accounts. I highly recommend to create them manually in the AWS console. Creating IAM
  user accounts via IaC comes with more problems than benefits.
