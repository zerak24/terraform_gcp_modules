data "google_client_config" "default" {}

data "google_container_cluster" "gke" {
  name     = format("%s-%s-eks", var.project.company, var.project.env)
  location = var.project.region
}

provider "kubernetes" {
  host                   = "https://${data.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.gke.ca_certificate)
}

module "workload-identity" {
  count  = var.role == null ? 0 : 1
  source = "git::https://github.com/terraform-google-modules/terraform-google-kubernetes-engine.git//module/workload-identity?ref=v33.0.1"

  project_id          = var.project.project_id
  location            = var.project.region
  name                = var.role.name
  gcp_sa_name         = format("%v-%v-role", var.project.env, var.role.name)
  namespace           = var.role.namespace
  roles               = var.role.roles
  cluster_name        = var.project.env
  annotate_k8s_sa     = true
  use_existing_k8s_sa = true
}