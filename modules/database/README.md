# Database
Relational Database Service is a fully managed database service. It simplifies the setup, operation, and scaling of
relational databases, making it easier for developers and businesses to deploy and manage database instances in the cloud.
RDS supports multiple database engines, including MySQL, PostgreSQL, Oracle, SQL Server, and MariaDB. We use PostgreSQL
at every project.

We deploy Aurora [serverless](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2-administration.html)
v2 cluster. Minimum ACU and maximum ACU are configurable. Deploying of the cluster takes 20-30 minutes depending on
your luck (overall workload in AZ that AWS selected for you on a random basis). By default two instances are deployed:
- Writer, which serves as a master instance services connects to.
- Reader, which can be used purely for read operations.

The reason why we deploy second reader instance is the failover process. If writer fails, reader is automaticaly promoted
to the new writer within 30 seconds. That's why instances are deployed in different availability zones. Database is not
publicly available and I don't recommend making it public. I'm trying to limit open doors of the infrastructure. `rds` security
group allows traffic only to port 5432 and tcp protocol.

RDS cluster config is stored as a string value in parameter store for possible future uses. It might be useful when you
want to configure access to the DB from within your IDE or pgAdmin. The content of SSM parameter looks like this:
```json
{
  "db_name": "go_api_template",
  "host": "go-api-template-postgres.cluster-chb4ficdk9sr.us-east-1.rds.amazonaws.com",
  "port": 5432,
  "username": "go_api_template"
}
```
RDS cluster password is stored as a secured string in parameter store so it's not exposed anywhere. The content is a plain
string, so it's prepared to be used for example in ECS task definition in the secrets section.

⚠️ If you know your application will be very small and you don't even expect big load and scaling in the future, I
recommend to use regular RDS and not the serverless one. Read [this](https://strvcom.atlassian.net/wiki/spaces/BE/pages/1888059393/Aurora)
for more information.
