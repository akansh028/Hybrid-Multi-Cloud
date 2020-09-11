// Provider
provider "kubernetes" {}



// creating Kubernetes service
resource "kubernetes_service" "terra_kube_wp_service" {
  metadata {
    name = "wp-service"
    labels = {
      app = "wordpress"
    }
  }
  spec {
    selector = {
      app = "wordpress"
      tier = "frontend"
    }
  port {
    node_port   = 30000 
    port        = 80
    target_port = 80
  }
  type = "NodePort"
 }
}



// creating a Kubernetes persistent volume claim
resource "kubernetes_persistent_volume_claim" "terra_pvc" {
  metadata {
    name = "pvc-vol"
    labels = {
      app = "wordpress"
      tier = "frontend"
    }
  }
  
  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}



// creating the Kubernetes deployment for Wordpress
resource "kubernetes_deployment" "terra_deploy" {
  metadata {
    name = "wordpress-deploy"
    labels = {
      app = "wordpress"
      tier = "frontend"
    }
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        app = "wordpress"
        tier = "frontend"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
          tier = "frontend"
        }
      }

      spec {
	volume {
	  name = "wp-persistent-storage"
	  persistent_volume_claim {
	    claim_name = kubernetes_persistent_volume_claim.terra_pvc.metadata.0.name
	  }
	}	
	
        container {
          image = "wordpress"
          name  = "wordpress-pod"
	  port {
	    container_port = 80
          }
          volume_mount {
	    name = "wp-persistent-storage"
	    mount_path = "/var/www/html"
	  }
        }

      }
    }
  }
}


	



