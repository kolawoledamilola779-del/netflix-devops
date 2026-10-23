# Netflix DevOps Project — Containerization, CI/CD & Amazon EKS

A full-stack movie application deployed using modern DevOps tools and cloud-native practices. This project brings together a React frontend, a Spring Boot backend, Docker, GitHub Actions, Amazon ECR, Amazon EKS, Kubernetes, and MongoDB Atlas.

The goal was to learn how to package an application, automate image builds, manage configuration, and deploy services to Kubernetes on AWS.

## Project Overview

The application allows users to browse movies and submit reviews. The frontend communicates with a REST API exposed by the backend, while MongoDB Atlas provides external database storage.

This repository consolidates the application code, container configuration, Kubernetes manifests, EKS configuration, and GitHub Actions workflows in one place.

## Architecture

```text
                         Users / Browser
                                |
                                v
                    AWS Application Load Balancer
                                |
                         Kubernetes Ingress
                          /             \
                         /               \
                        v                 v
                React Frontend       Spring Boot API
                   Service              Service
                        |                 |
                        v                 v
                Frontend Pod         Backend Pod
                                          |
                                          v
                                    MongoDB Atlas

Source Code
     |
     v
GitHub Repository
     |
     v
GitHub Actions Workflows
     |
     v
Build and Containerize Applications
     |
     v
Amazon ECR
     |
     v
Amazon EKS Deployments
```

*Note: GitHub Actions builds and pushes container images to Amazon ECR. Kubernetes deployment updates are managed separately; the workflows do not currently apply the Kubernetes manifests automatically.*

## Technology Stack

| Area | Technologies |
|---|---|
| Frontend | React, JavaScript, Node.js |
| Backend | Java, Spring Boot, Maven |
| Database | MongoDB Atlas |
| Containerization | Docker, Docker Compose |
| CI/CD | GitHub Actions |
| Container Registry | Amazon ECR |
| Orchestration | Kubernetes, Amazon EKS |
| Networking | AWS VPC, public and private subnets, NAT Gateway |
| Application Routing | Kubernetes Ingress, AWS Application Load Balancer |
| Authentication for CI | GitHub Actions OIDC with AWS IAM |

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── backend-cicd.yaml
│       └── frontend-cicd.yaml
├── k8s/
│   ├── backend-deployment.yaml
│   ├── backend-service.yaml
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml
│   └── ingress.yaml
├── netflix-backend/
│   ├── Dockerfile
│   ├── pom.xml
│   └── src/
├── netflix-frontend/
│   ├── Dockerfile
│   ├── docker-entrypoint.sh
│   ├── package.json
│   ├── public/
│   └── src/
├── compose.yaml
├── eks-cluster.yaml
└── .gitignore
```

## Key DevOps Implementations

### 1. Docker Containerization

Dockerfiles package the frontend and backend into containers. This makes the application easier to run consistently across development and deployment environments.

Docker Compose defines the local frontend and backend services in one configuration.

### 2. GitHub Actions CI/CD

Two workflows separate frontend and backend build processes:

- **Backend workflow:** sets up Java 17, builds the Spring Boot application with Maven, builds a Docker image, and pushes it to Amazon ECR.
- **Frontend workflow:** sets up Node.js 18, installs dependencies, builds the React application, builds a Docker image, and pushes it to Amazon ECR on push events.

The workflows use path filters so changes to one application can trigger its corresponding workflow.

### 3. Secure AWS Authentication with OIDC

The workflows use GitHub Actions OpenID Connect (OIDC) to request AWS credentials through IAM roles, rather than storing long-lived AWS access keys in the repository.

The IAM role trust policies must allow the new GitHub repository and the appropriate branch or event context before these workflows can authenticate successfully.

### 4. Amazon ECR

Amazon Elastic Container Registry stores the container images used by the Kubernetes deployments.

Images are tagged with the Git commit SHA, making it easier to identify which source revision produced a particular image.

### 5. Amazon EKS and Kubernetes

Amazon Elastic Kubernetes Service runs the application on managed worker nodes.

The Kubernetes manifests define:

- Deployments for the frontend and backend.
- ClusterIP Services for internal communication.
- An Ingress resource that routes frontend and API traffic through an AWS Application Load Balancer.
- A dedicated `netflix` namespace for application resources.

The cluster configuration uses a VPC with public and private subnets. Worker nodes are configured for private networking, with outbound connectivity provided through a NAT Gateway.

### 6. External Database Configuration

MongoDB Atlas is used as the external database.

The backend reads its database configuration from environment variables supplied through a Kubernetes Secret named `netflix-mongodb-secret`. Database credentials are kept out of the Kubernetes Deployment manifest.

### 7. Frontend Runtime Configuration

The frontend includes a runtime configuration mechanism using `config.js` and `docker-entrypoint.sh`. The container entrypoint generates frontend API configuration from the `API_URL` environment variable.

This approach is intended to allow API endpoint configuration to change at container startup without rebuilding the frontend image, provided the image is built with the runtime configuration mechanism and the deployment supplies the correct value.

## Running Locally

### Prerequisites

Install:

- Git
- Docker Desktop with Docker Compose
- A MongoDB Atlas database
- Java 17 and Node.js if you also want to run or debug the applications outside Docker

### 1. Configure the backend environment

Create a local environment file at `netflix-backend/.env`.

Add your own database configuration:

```dotenv
MONGO_DATABASE=your_database_name
MONGO_URI=your_mongodb_connection_string
```

Replace the example values with your own settings. Ensure your MongoDB Atlas network access rules and database user permissions allow the application to connect.

**Never commit this file or publish your real database connection string.**

### 2. Start the application

From the repository root, run:

```bash
docker compose up --build
```

The Compose configuration maps the backend to port `8080` and the frontend to port `3001`.

When the containers are running, try:

- Frontend: `http://localhost:3001`
- Backend API: `http://localhost:8080/api/v1/movies`

To stop the application:

```bash
docker compose down
```

If the frontend cannot reach the backend, verify the frontend's API configuration and the browser's network requests. A browser cannot use the Compose service name `backend` as if it were a public hostname; frontend requests need an address reachable from the browser.

## Deploying to Amazon EKS

The repository contains an `eks-cluster.yaml` configuration and Kubernetes manifests for the application.

The current cluster configuration references an existing AWS VPC and subnet IDs in `us-east-1`. These identifiers are specific to that environment and are not a portable, one-click cluster setup.

A high-level deployment process is:

1. Configure AWS CLI access and verify the target AWS account and region.
2. Ensure the VPC, subnets, routing, IAM permissions, and EKS prerequisites are configured correctly.
3. Build the frontend and backend container images.
4. Push the images to the appropriate Amazon ECR repositories.
5. Configure the Kubernetes namespace and the `netflix-mongodb-secret` with the required database environment variables.
6. Update the image references in the Kubernetes Deployment manifests to the intended ECR image tags.
7. Apply the Kubernetes manifests and verify the Deployments, Pods, Services, and Ingress.
8. Confirm that the AWS Load Balancer is provisioned and test the frontend and API routes.

**Important:** the checked-in Deployment manifests currently reference specific ECR image tags. A new image pushed to ECR does not automatically change the image used by an existing Kubernetes Deployment. Update the manifests and apply them, or implement a deployment stage in CI/CD, when rolling out a new version.

Review the AWS resources and their costs before creating or modifying infrastructure. NAT Gateways, EKS control planes, worker nodes, load balancers, and related services can incur charges.

## Challenges and Lessons Learned

Working through this project involved learning how individual application components behave when moved from a local environment to containers and Kubernetes.

Areas explored included:

- Diagnosing connectivity between frontend and backend services.
- Managing database configuration without hardcoding credentials into application source.
- Building and tagging Docker images for Amazon ECR.
- Configuring GitHub Actions to authenticate to AWS through OIDC.
- Understanding Kubernetes Deployments, Services, namespaces, and Ingress routing.
- Using private worker nodes with outbound access through a NAT Gateway.
- Troubleshooting deployment configuration and image-version mismatches.
- Separating image publication from Kubernetes rollout automation.

These experiences reinforced the importance of understanding networking, configuration, container images, IAM permissions, and observability when deploying applications to the cloud.

## Future Improvements

- Add automated tests and stronger quality gates to CI.
- Add a dedicated deployment stage to update Kubernetes after a successful image push.
- Use a safer image promotion strategy and automate rollout verification.
- Add monitoring, centralized logging, and alerting.
- Make infrastructure configuration reusable across environments.
- Improve secret management and document environment setup in more detail.

## Project Status

This repository consolidates the application and deployment configuration for learning and portfolio purposes. The CI workflows build and publish images; Kubernetes rollout automation, production-grade monitoring, and other improvements remain potential next steps.

## Security Notes

- Do not commit `.env` files, database connection strings, access keys, or tokens.
- Use GitHub Actions OIDC with appropriately scoped IAM roles.
- Store Kubernetes database configuration in Kubernetes Secrets or an appropriate secrets manager.
- Review the AWS IAM trust policies and resource permissions before enabling workflows in a new repository.
- Treat AWS infrastructure identifiers as environment-specific configuration.

---

**Project focus:** Containerization, CI/CD, AWS, Kubernetes, networking, runtime configuration, and deployment troubleshooting.
