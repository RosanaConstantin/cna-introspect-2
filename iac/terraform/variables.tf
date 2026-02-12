variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "claim-eks-cluster"
}

variable "ecr_repo" {
  type    = string
  default = "claim-api"
}

variable "claims_table" {
  type    = string
  default = "claims"
}

variable "notes_bucket" {
  type    = string
  default = "claim-notes-bucket"
}
