variable "name" {
  type = string
  description = "Your username. Will be prepended to most resource names to track what's yours."
}

variable "region" {
  type = string
  description = "The region where you would like to deploy this infrastructure."
  default = "us-west-2"
}
