# clicamos-ops

This project aims to demonstrate rolling deployments with 0 down-time using packer, terraform and aws.

It provides a VPC with public subnet for a NAT server and private subnet which is holding the auto-scaling
instances which are accessible trough a load balancer.


Being mainly terraform project, this is using a module, the mod-network, that is hosted in a different repository.

The `mod-network` adds the following structure to the environment:

![Alt text](nat-instance-diagram.png?raw=true)

How this works? Let me just copy what aws documentation says:

    "The main route table is associated with the private subnet and sends the traffic from
    the instances in the private subnet to the NAT instance in the public subnet.
    The NAT instance sends the traffic to the Internet gateway for the VPC.
    The traffic is attributed to the Elastic IP address of the NAT instance.
    The NAT instance specifies a high port number for the response; if a response comes back,
    the NAT instance sends it to an instance in the private subnet based on the
    port number for the response."

Our nat server will be using a docker container with the openVPN installed. 
You can see more details on the module repository https://github.com/fonsecas72/mod-network


##### Some details, info and documentation


Networking apart, on top of all we will be having a load balancer:

    A load balancer distributes incoming application traffic across multiple EC2 instances
    in multiple Availability Zones. This increases the fault tolerance of your applications.
    Elastic Load Balancing detects unhealthy instances and routes traffic only to healthy instances.
    Your load balancer serves as a single point of contact for clients.

    This increases the availability of your application. You can add and remove instances from your
    load balancer as your needs change, without disrupting the overall flow of requests to your
    application. Elastic Load Balancing scales your load balancer as traffic to your application
    changes over time. Elastic Load Balancing can scale to the vast majority of workloads automatically.

    A listener checks for connection requests from clients, using the protocol and port that you configure,
    and forwards requests to one or more registered instances using the protocol and port number that you configure.

We are using this config, that you can see in the app-servers.tf file:

```
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
```

Which means we are simply redirecting traffic from port 80 to port 80 of our instances.

But this load balancer will also work closely with Auto Scaling:

    Auto Scaling helps you ensure that you have the correct number of Amazon EC2 instances available to
    handle the load for your application.
    You can specify the minimum and maximum number of instances in each Auto Scaling group.

And auto scaling groups need Launch Configurations (or launch template) to work.
This launch configuration is where we are going to specify the app AMI with the project already deployed.


#### Deployment process - 0 downtime

Terraform will create a new launch configuration and a new auto scaling group,but
re-uses the existing elastic load balancer.
The new auto scaling group will boot their instances using the new AMI and once
these instances are passing the ELB health checks, Terraform will remove the old
ones. If there is a problem with the new instances (in our case if port 80 is not responding)
Terraform will leave the old instances untouched and everything will keep on working.
This while process will make your app to have 0 downtime since load balancer will
immediately start sending requests to the new instances once they pass the health checks.


![Alt text](load_balancer.png?raw=true)

##### How to

To build the AMI:

```
packer build -machine-readable packer/app-server.json | tee build.log
"AMI=$(grep 'artifact,0,id' build.log | cut -d, -f6 | cut -d: -f2)"
echo "ami = \""$AMI"\"" > ami.tfvars
```

(you can just run `packer build packer/app-server.json` but then you'll need to note the resulting AMI and give that to the following command)

To deploy structure (you'll need AWS access and secret keys)

terraform init
terraform apply -var-file=ami.tfvars
```

##### Directories/Files:

    packer
    - The "packer" folder holds configurations regarding the AMI creation.
    packer/vagrant
    - You can use the "packer/vagrant" folder to test the deployment provisioning.
    packer/vagrant/ssh
    - private&pub key used when building the ami and to access it later
    user_data
    - just holds a script for extra config we need before we launch the app instances
    ami.tfvars
    - vars file that should old the app AMI to be deployed
    app-servers.tf
    - Load Balancer & Auto-Scaling configurations
    main.tf
    - General terraform configurations and variables
    outputs.tf
    - Every terraform outputs configurations
    security-groups.tf
    - Security groups used for Application and Load Balancer
    variables.tf
    - General definition of variables to be used during terraform apply

