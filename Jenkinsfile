pipeline {
  agent any

  options {
    disableConcurrentBuilds()
    timestamps()
  }

  parameters {
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'Región de AWS')
    string(name: 'AWS_ACCOUNT_ID', defaultValue: '', description: 'ID de cuenta AWS')
    string(name: 'ECR_REPOSITORY', defaultValue: '', description: 'Repositorio ECR existente')
    string(name: 'TF_STATE_BUCKET', defaultValue: '', description: 'Bucket S3 ya creado para el estado Terraform')
    string(name: 'TF_STATE_KEY', defaultValue: 'ecs-frontend/dev/terraform.tfstate', description: 'Clave del estado Terraform')
    string(name: 'VPC_ID', defaultValue: '', description: 'ID de VPC existente')
    string(name: 'PUBLIC_SUBNET_IDS', defaultValue: '[]', description: 'IDs de subredes públicas, formato JSON')
    string(name: 'PRIVATE_SUBNET_IDS', defaultValue: '[]', description: 'IDs de subredes privadas, formato JSON')
  }

  environment {
    AWS_DEFAULT_REGION = "${params.AWS_REGION}"
    ECR_REGISTRY = "${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        script {
          env.GIT_COMMIT = sh(script: 'git rev-parse --short=12 HEAD', returnStdout: true).trim()
          env.IMAGE_URI = "${params.AWS_ACCOUNT_ID}.dkr.ecr.${params.AWS_REGION}.amazonaws.com/${params.ECR_REPOSITORY}:${env.GIT_COMMIT}"
        }
      }
    }

    stage('Validate Terraform') {
      steps {
        dir('terraform') {
          sh '''
            terraform fmt -check -recursive
            terraform init -backend=false -input=false
            terraform validate
          '''
        }
      }
    }

    stage('Build and smoke test') {
      steps {
        sh '''
          docker build --pull -t ecs-frontend-demo:${GIT_COMMIT} .
          container_id=$(docker run -d --rm "ecs-frontend-demo:${GIT_COMMIT}")
          trap 'docker stop "$container_id" >/dev/null 2>&1 || true' EXIT
          for attempt in $(seq 1 15); do
            if docker exec "$container_id" wget -q -O - http://127.0.0.1/ | grep -F '<title>Frontend on ECS Fargate</title>' >/dev/null; then
              exit 0
            fi
            sleep 1
          done
          echo 'El contenedor no respondió correctamente en /' >&2
          exit 1
        '''
      }
    }

    stage('Publish image') {
      when {
        branch 'main'
      }
      steps {
        sh '''
          aws ecr get-login-password --region "$AWS_DEFAULT_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"
          docker tag "ecs-frontend-demo:${GIT_COMMIT}" "$IMAGE_URI"
          docker push "$IMAGE_URI"
        '''
      }
    }

    stage('Deploy dev') {
      when {
        branch 'main'
      }
      steps {
        dir('terraform') {
          sh '''
            terraform init -input=false \
              -backend-config="bucket=${TF_STATE_BUCKET}" \
              -backend-config="key=${TF_STATE_KEY}" \
              -backend-config="region=${AWS_DEFAULT_REGION}" \
              -backend-config="use_lockfile=true" \
              -backend-config="encrypt=true"
            terraform plan -input=false -out=tfplan \
              -var="region=${AWS_DEFAULT_REGION}" \
              -var="environment=dev" \
              -var="container_image=${IMAGE_URI}" \
              -var="vpc_id=${VPC_ID}" \
              -var="public_subnet_ids=${PUBLIC_SUBNET_IDS}" \
              -var="private_subnet_ids=${PRIVATE_SUBNET_IDS}"
            terraform apply -input=false tfplan
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker image rm "ecs-frontend-demo:${GIT_COMMIT}" >/dev/null 2>&1 || true'
    }
  }
}