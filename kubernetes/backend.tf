resource "kubernetes_deployment" "backend" {
  metadata {
    name = "backend-deploy"
    labels = {
      App = local.backend
    }
  }

  spec {
    replicas = 2
    selector {
      match_labels = {
        App = local.backend
      }
    }
    template {
      metadata {
        labels = {
          App = local.backend
        }
      }
      spec {
        container {
          image = "nginx"
          name  = "backend"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "256Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [ kubernetes_stateful_set.postgres ]
}

resource "kubernetes_service" "backend" {
  metadata {
    name = "backend-svc"
  }
  spec {
    selector = {
      App = local.backend
    }
    port {
      node_port   = 30002
      port        = 80
      target_port = 80
    }
    type = "NodePort"
  }
}

resource "kubernetes_horizontal_pod_autoscaler" "backend" {
  metadata {
    name = "backend-hpa"
  }

  spec {
    min_replicas = 2
    max_replicas = 8

    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = "backend-deploy"
    }

    target_cpu_utilization_percentage = 80
  }
}