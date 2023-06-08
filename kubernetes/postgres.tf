resource "kubernetes_persistent_volume" "postgres" {
  metadata {
    name = "postgres-pv"
  }
  spec {
    capacity = {
      storage = "10Gi"
    }
    storage_class_name = "standard"
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      nfs {
        server = local.nfs_ip
        path = local.nfs_postgres_path
        read_only = false
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name = "postgres-pvc"
  }
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "standard"
    volume_name = "postgres-pv"
  }
  depends_on = [ kubernetes_persistent_volume.postgres ]
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name = "postgres-statefulset"
    labels = {
      App = local.postgres
    }
  }

  spec {
    replicas = 2
    service_name = local.postgres
    selector {
      match_labels = {
        App = local.postgres
      }
    }
    template {
      metadata {
        labels = {
          App = local.postgres
        }
      }
      spec {
        container {
          name  = "postgres"
          image = "postgres:13"
          port {
            container_port = 5432
          }
          
          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = "postgres"
          }
          env {
            name  = "POSTGRES_DB"
            value = "postgres_db"
          }
          volume_mount {
            name       = "postgres-data"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "postgres-data"
          persistent_volume_claim {
            claim_name = "postgres-pvc"
          }
        }
      }
    }
  }
  depends_on = [ kubernetes_persistent_volume_claim.postgres ]
}

resource "kubernetes_service" "postgres_svc" {
  metadata {
    name = "postgres-svc"
  }
  spec {
    selector = {
      App = local.postgres
    }
    port {
      port        = 5432
      target_port = 5432
    }
  }
}