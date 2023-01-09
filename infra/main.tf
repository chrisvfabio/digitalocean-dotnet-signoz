terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}

resource "digitalocean_project" "project" {
  name = "upwork-32321074"
  resources = [
    digitalocean_app.dotnet-sample.urn,
    digitalocean_kubernetes_cluster.sample-cluster.urn,
  ]
}

resource "digitalocean_app" "dotnet-sample" {
  spec {
    name   = "dotnet-sample"
    region = "sgp"

    service {
      name               = "dotnet-service"
      http_port          = 80
      instance_count     = 1
      instance_size_slug = "basic-xxs"
      source_dir         = "apps/sample-api"
      dockerfile_path    = "apps/sample-api/Dockerfile"

      health_check {
        http_path = "/healthz"
      }

      github {
        repo           = "chrisvfabio/digitalocean-dotnet-signoz"
        branch         = "main"
        deploy_on_push = true
      }
    }
  }
}

resource "digitalocean_kubernetes_cluster" "sample-cluster" {
  name   = "k8s-sample-cluster"
  region = "sgp1"
  version = "1.25.4-do.0"

  node_pool {
    name       = "pool-1"
    size       = "s-4vcpu-8gb"
    node_count = 1
  }
}
