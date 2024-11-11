# Service
Elastic Container Service is a fully managed container orchestration service. It simplifies the deployment, management,
and scaling of containerized applications using Docker containers. ECS is designed to help developers and organizations
run containers at scale and is closely integrated with other AWS services.

There are plenty of resources, so let's start from the beginning of the file. Our Go backend template requires a bunch of
configuration parameters and some of them are sensitive. For this reason, we use SSM parameters to store them. These include
Firebase credentials and swagger name and password. When adding a new SMM parameter, don't forget to add it to the
`ecs_task_execution_api` IAM policy so the service has permission to fetch the parameter.

Follows the definition of ECS cluster with task definition and service. All these resources are interconnected. You need to have
a cluster to deploy a service, but the service needs task definition to be able to start. Cluster is a very simple resource,
it is just a wrapper around services. Next, there is task definition. We refer to existing Docker image with a version that
is configurable. Follows environment configuration. Some of the environment variables are static so they are delivered via
the configuration file. The rest of the variables are dynamic ones, such as the data source name to the database, or SSM
parameters containing sensitive values, which belong to the `secrets` section. A log group for the task is deployed beforehand,
so the task just refers to the existing one. Next, we provide maximum CPU and memory, which are configurable parameters.
As an execution role, we use a custom one that is composed of two separate policies - `common` and `api`. `common` is suitable
for all services as it contains ECR and logs related actions, while the `api` policy is API specific and contains for example
access to SSM sensitive configuration parameters. Task role is also custom but for template purposes, it contains only S3 policy.
The last created resource in this logical group is the service, which refers to the already existing cluster and task definition.
Don't forget on security group that accepts all ingress and egress traffic - we don't have to have any limitations here.

With this configuration, you deployed the cluster with the service. But still, there are several problems:
- It is not reachable from the Internet.
- What about scaling?
- Is the service even healthy?

## Load balancer with health check
We start from the end. The flow is like that: load balancer listener -> load balancer target group -> service. We missed the
first two resources. We deploy the target group with HTTP protocol and the same port our application is running on. Then there
is the health check definition. In Go APIs, we have endpoint `/ping` that serves this purpose. Next, you define other
fields such as expected status code, threshold, and interval. The service references this target group. But something needs
to refer to the target group. It is a load balancer listener, where we set just port, protocol, and action (forward to target group).

## Scaling
The next mentioned topic is scaling. It is done by autoscaling resources. At this time, the `TargetTrackingScaling` policy is
applied, which is very simple. The scaling policy tracks the CPU and the memory of the service. By default, in both cases,
the target value is set to 70. That means the service tries to keep the CPU and memory at 70%. If there is a high load and CPU
or memory goes above, the service is scaled up. Minimum and maximum instance counts are configurable. By default, it is 1
at minimum and 2 at maximum. Regarding CPU and memory, by default, the CPU is set to 512, which means 0.5 vCPU, and memory is set
to 1024, which means 1 GiB. Values are, of course, configurable. The last part of autoscaling is cooldown. We have set scale
in and scale out cooldowns. If the scaling happens, the service waits for 60 seconds before it potentially scales again to
prevent service spamming.

## Public access
Finally, we've got to the remaining topic from the previous section and it is making our service publicly accessible.
For this purpose, the load balancer isn't set as internal but as public. Since we don't have a dedicated domain for the template,
the load balancer works without a certificate on port 80. It's sufficient for this minimalistic template but in a real project,
you will have indeed a domain. In that case, you would do the following:
- Create a Route 53 hosted zone.
- Create a certificate for the hosted zone.
- Create an A record with an alias to the load balancer.
- Modify resource `aws_lb_listener.this`:
  - `port` to 443.
  - `protocol` to HTTPS.
  - Set `certificate_arn`.
- Modify resource `aws_security_group.this`:
  - `from_port` to 443.
  - `to_port` to 443.

## Roles
ECS tasks need of course appropriate roles to be able to start and communicate with other services. For this reason, this module
provisions both task execution role and task role:
- `ECS task execution role`: The task execution role grants the ECS container and Fargate agents permission to make
  API calls on your behalf, such as authorizing to ECR, downloade Docker image or put logs to CloudWatch.
- `ECS task role`: The permissions granted in the role are assumed by the containers running in the task. It's beneficial
  for applications, which need to call AWS APIs, such as S3. Task role in the template contains only S3 policy although
  it's not needed for this template. It's here just an example so a developer can easily modify it.

⚠️ Note, that we don't have a custom URL. For the template, the auto-generated public URL of the load balancer is good enough.
