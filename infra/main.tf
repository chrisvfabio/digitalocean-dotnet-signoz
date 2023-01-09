terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  #   token = var.do_token - DIGITALOCEAN_TOKEN env
}

resource "digitalocean_app" "dotnet-sample" {
  spec {
    name   = "dotnet-sample"
    region = "sgp1"

    service {
      name               = "dotnet-service"
      instance_count     = 1
      instance_size_slug = "basic-xxs"
      source_dir         = "apps/sample-api"
      dockerfile_path    = "apps/sample-api/Dockerfile"

      github {
        repo           = "chrisvfabio/digitalocean-dotnet-signoz"
        branch         = "main"
        deploy_on_push = true
      }
    }
  }
}


# resource "digitalocean_kubernetes_cluster" "foo" {
#   name   = "foo"
#   region = "nyc1"
#   # Grab the latest version slug from `doctl kubernetes options versions`
#   version = "1.22.8-do.1"

#   node_pool {
#     name       = "worker-pool"
#     size       = "s-2vcpu-2gb"
#     node_count = 3

#     taint {
#       key    = "workloadKind"
#       value  = "database"
#       effect = "NoSchedule"
#     }
#   }
# }
