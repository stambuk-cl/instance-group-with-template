resource "google_service_account" "default" {
  account_id   = "sa-for-tf-poc"
  display_name = "Service Account for TF POC"
}

resource "google_compute_instance_template" "default" {
  name        = "template-app"
  description = "This template is used to create app server instances."

  tags = ["instancegroup"]

  labels = {
    environment = "dev" ##DEV - QA - PROD
  }

  instance_description = "description assigned to instances"
  machine_type         = "e2-medium"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
    // backup the disk every day
    resource_policies = [google_compute_resource_policy.daily_backup.id]
  }

  // Use an existing disk resource
  disk {
    // Instance Templates reference disks by name, not self link
    source      = google_compute_disk.disk1.name
    auto_delete = false
    boot        = false
  }

  network_interface {
    network = "default"
  }

  metadata = {
    foo = "bar"
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email = google_service_account.default.email
    scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/compute.readonly",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/source.read_only",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform.read-only"
    ]
  }
}

data "google_compute_image" "image1" {
  family  = "debian-9"
  project = "debian-cloud"
}

resource "google_compute_disk" "disk1" {
  name  = "disk-for-appserver"
  image = data.google_compute_image.image1.self_link
  size  = 10
  type  = "pd-ssd"
  zone  = "us-central1-a"
}

resource "google_compute_resource_policy" "daily_backup" {
  name   = "every-day-4am"
  region = "us-central1"
  snapshot_schedule_policy {
    schedule {
      daily_schedule {
        days_in_cycle = 1
        start_time    = "04:00"
      }
    }
  }
}