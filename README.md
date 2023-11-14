# Terraform Infrastructure for Ghost CMS on AWS

Welcome to the Terraform infrastructure setup for deploying the Ghost CMS on AWS! This README provides a comprehensive overview of the infrastructure components and their configurations. Below, we'll walk you through each service as part of the setup.

## OIDC Authentication and GitHub Actions

This setup utilizes OIDC (OpenID Connect) authentication to securely connect to AWS and automate the deployment of the Ghost CMS using GitHub Actions.

**OIDC Authentication**: OIDC is employed to establish a secure and authenticated connection to AWS. OIDC provides a standardized way to verify the identities of users or services.

**GitHub Actions Integration**: GitHub Actions is utilized to automate the Terraform deployment process. With OIDC authentication configured, GitHub Actions can securely authenticate with AWS and execute Terraform scripts.

The integration between OIDC, AWS, and GitHub Actions ensures that your infrastructure deployments are both automated and secure.

## Elastic Container Registry (ECR) Repository

The Elastic Container Registry (ECR) is a managed Docker container registry service by AWS. In this setup, an ECR repository named "ghost" is created to store Docker images securely.

ECR allows you to version and manage your Docker images efficiently, ensuring that your Ghost CMS container image is readily available for deployment.

## Docker Image Build and Push to ECR

To deploy applications using containers, it's crucial to build and push Docker images to ECR. This step is facilitated using Terraform's provisions and local-exec provisioners to execute Docker commands.

Building and pushing the Docker image ensures that you have a containerized Ghost CMS ready for deployment.

## ECR VPC Endpoints

Security and isolation are vital when dealing with container registries. To enhance security, Virtual Private Cloud (VPC) endpoints are set up for both ECR API and Docker services.

These endpoints allow private and secure communication between your VPC and ECR, eliminating the need for public internet access when interacting with the container registry.

## VPC and Subnets

A Virtual Private Cloud (VPC) provides isolated network resources for your infrastructure, while subnets are logical segments within the VPC. In this setup, a VPC and subnets are created to organize your infrastructure logically.

The VPC and subnets ensure that your infrastructure components are properly isolated and can be configured as public or private as needed.

## Security Groups

Security groups serve as virtual firewalls, controlling inbound and outbound traffic to AWS resources. Security groups for Fargate services and an Application Load Balancer (ALB) are defined in this setup.

These security groups allow you to specify which traffic is allowed to reach your ECS tasks and ALB, enhancing your infrastructure's security posture.

## IAM Roles and Policies

Identity and Access Management (IAM) roles and policies are crucial for managing permissions and access to AWS resources. In this setup, IAM roles are defined for ECS tasks and execution.

These roles are associated with policies that allow ECS tasks to access ECR and send logs to CloudWatch, ensuring that your Ghost CMS containers can function effectively.

## ECS Cluster and Service

Amazon Elastic Container Service (ECS) is used to manage containers in this setup. An ECS cluster and service are defined to host the Ghost CMS.

ECS provides a scalable and efficient platform for running containers, and AWS Fargate abstracts the underlying infrastructure, making it easier to manage and scale your application.

## Application Load Balancer (ALB)

An Application Load Balancer (ALB) is a crucial component for distributing incoming traffic to ECS service instances. The ALB is configured to ensure that traffic is routed appropriately to your Ghost CMS containers.

The ALB acts as a traffic controller, allowing your application to handle incoming requests efficiently.

## Amazon RDS (Relational Database Service)

While the code mentions Amazon RDS, the actual resource definition is not included in this README. You can configure an Amazon RDS instance separately to store the database for your Ghost CMS.

Amazon RDS is a managed database service that offers reliability, scalability, and security for your database needs.

This README provides an in-depth look at the Terraform infrastructure for deploying the Ghost CMS on AWS. To get started, follow the deployment steps mentioned earlier, and customize the code to meet your specific requirements.

For any questions or further assistance, please feel free to reach out. Happy deploying





