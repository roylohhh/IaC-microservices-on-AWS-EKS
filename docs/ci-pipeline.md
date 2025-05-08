# Workflow Overview
Workflow file: .github/workflows/ci.yml
Triggers: Runs on push to main or develop branches.

## Pipeline Steps
**1. Checkout Code**

Fetches the latest commit from the repository.

```
- name: Checkout source code
  uses: actions/checkout@v4
```

**2. Set Up Java 21 Environment**

Configures Java using Temurin distribution.

```
- name: Set up JDK
  uses: actions/setup-java@v4
  with:
    distribution: 'temurin'
    java-version: '21'
```

**3. Build with Maven (Tests Skipped)**

Compiles the Spring Boot application. Environment variables for the build are passed securely from GitHub Actions vars.

```
- name: Build with Maven
  run: ./mvnw clean install -DskipTests
  env:
    DB_HOST: ${{ vars.DB_HOST }}
    DB_NAME: ${{ vars.DB_NAME }}
    DB_USERNAME: ${{ vars.DB_USERNAME }}
    DB_PASSWORD: ${{ vars.DB_PASSWORD }}
```

**4. Configure AWS Credentials**

Grants access to AWS using credentials stored in GitHub Secrets.

```
- name: Set Up AWS Credentials
  uses: aws-actions/configure-aws-credentials@v3
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: ${{ secrets.AWS_REGION }}
```

**5. Log In to Amazon ECR**

Logs in to Amazon ECR (Elastic Container Registry), allowing Docker commands to push images to your private container registry.
```
- name: Log in to Amazon ECR
  uses: aws-actions/amazon-ecr-login@v2
```

**6. Generate Image Tag from Git Commit SHA**

Uses Git to extract the current commit's short SHA (ab1b2c3d etc) and sets it as an environment variable IMAGE_TAG. This ensures that each image pushed to ECR is versioned with the commit that produced it.
```
- name: Extract Git commit SHA
  run: echo "IMAGE_TAG=$(git rev-parse --short HEAD)" >> $GITHUB_ENV
```

**7. Build and Tag Docker Image**

First builds the Docker image locally. Then tags it with the full ECR repository path so it’s ready for upload.
```
- name: Build Docker image
  run: |
    docker build -t ${{ secrets.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }} .

- name: Tag Docker image
  run: |
    docker tag ${{ secrets.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }} \
    ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/${{ secrets.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }}
```

**8. Push Image to ECR**

Uploads the Docker image to your ECR registry so it can be deployed by Kubernetes or ArgoCD.
```
- name: Push Docker image to Amazon ECR
  run: |
    docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.${{ secrets.AWS_REGION }}.amazonaws.com/${{ secrets.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }}
```