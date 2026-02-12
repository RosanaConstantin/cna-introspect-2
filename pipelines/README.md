# CI/CD Pipelines

This folder contains CodeBuild buildspecs and a sample CodePipeline definition.

- buildspec-build.yml: build and push image to ECR
- buildspec-deploy.yml: kubectl apply manifests to EKS
- codepipeline.yaml: sample pipeline stages (Source → Build → Deploy)
