# Terraform Infrastructure for Ghost CMS on AWS

Welcome to the Terraform infrastructure setup for deploying the Ghost CMS on AWS! This README provides a comprehensive overview of the infrastructure components and their configurations. Below, we'll walk you through each service as part of the setup.

## OIDC Authentication and GitHub Actions

This setup utilizes OIDC (OpenID Connect) authentication to securely connect to AWS and automate the deployment of the Ghost CMS using GitHub Actions.

**OIDC Authentication**: OIDC is employed to establish a secure and authenticated connection to AWS. OIDC provides a standardized way to verify the identities of users or services.

**GitHub Actions Integration**: GitHub Actions is utilized to automate the Terraform deployment process. With OIDC authentication configured, GitHub Actions can securely authenticate with AWS and execute Terraform scripts.

The integration between OIDC, AWS, and GitHub Actions ensures that the infrastructure deployments are both automated and secure.

**Secure Storage of Credentials**: To ensure the security of the credentials, usernames, and passwords are stored as GitHub Secrets. GitHub Secrets provide a secure way to store sensitive information, keeping authentication details safe.

## Elastic Container Registry (ECR) Repository

The Elastic Container Registry (ECR) is a managed Docker container registry service by AWS. In this setup, an ECR repository named "ghost" is created to store Docker images securely.

ECR allows you to version and manage Docker images efficiently, ensuring that the Ghost CMS container image is readily available for deployment.

## Docker Image Build and Push to ECR

To deploy applications using containers, it's crucial to build and push Docker images to ECR. This step is facilitated using Terraform's provisions and local-exec provisioners to execute Docker commands.

Building and pushing the Docker image ensures that you have a containerized Ghost CMS ready for deployment.

## ECR VPC Endpoints

Security and isolation are vital when dealing with container registries. To enhance security, Virtual Private Cloud (VPC) endpoints are set up for both ECR API and Docker services.

These endpoints allow private and secure communication between your VPC and ECR, eliminating the need for public internet access when interacting with the container registry.

## VPC and Subnets

A Virtual Private Cloud (VPC) provides isolated network resources for the infrastructure, while subnets are logical segments within the VPC. In this setup, a VPC and subnets are created to organize your infrastructure logically.

The VPC and subnets ensure that the infrastructure components are properly isolated and can be configured as public or private as needed.

## Security Groups

Security groups serve as virtual firewalls, controlling inbound and outbound traffic to AWS resources. Security groups for Fargate services and an Application Load Balancer (ALB) are defined in this setup.

These security groups allow you to specify which traffic is allowed to reach ECS tasks and ALB, enhancing the infrastructure's security posture.

## IAM Roles and Policies

Identity and Access Management (IAM) roles and policies are crucial for managing permissions and access to AWS resources. In this setup, IAM roles are defined for ECS tasks and execution.

These roles are associated with policies that allow ECS tasks to access ECR and send logs to CloudWatch, ensuring that the Ghost CMS containers can function effectively.

## ECS Cluster and Service

Amazon Elastic Container Service (ECS) is used to manage containers in this setup. An ECS cluster and service are defined to host the Ghost CMS.

ECS provides a scalable and efficient platform for running containers, and AWS Fargate abstracts the underlying infrastructure, making it easier to manage and scale the application.

## Application Load Balancer (ALB)

An Application Load Balancer (ALB) is a crucial component for distributing incoming traffic to ECS service instances. The ALB is configured to ensure that traffic is routed appropriately to the Ghost CMS containers.

The ALB acts as a traffic controller, allowing the application to handle incoming requests efficiently.

## Amazon RDS (Relational Database Service)


# Terraform Infrastructure and Pipeline Status

The core of this deployment lies within the Terraform configuration files, where you define the infrastructure components and their configurations. The infrastructure-as-code (IAC) approach allows to manage and version infrastructure efficiently.

# Pipeline Status

Currently, I am experiencing challenges with the GitHub Actions pipeline linked to this project. The primary issue stems from certain misconfigurations that are disrupting its expected functionality. Within the scope of these pipelines, there are segments that operate correctly. However, I am encountering specific problems related to ECS connectivity with the RDS. The latest pipelines are intended to add the necessary components, assuming they would function correctly.

For any questions please feel free to reach out.





