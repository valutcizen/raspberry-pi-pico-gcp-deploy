terraform {
  backend "gcs" {
    prefix = "pipico_programmer_state"
  }
}

provider "google" {
  project = var.project
  region  = var.region
  zone    = var.zone
}

resource "google_service_account" "sa_pipico_programmer" {
  account_id = "pipico-programmer"
}

resource "google_pubsub_topic" "topic_pipico" {
  name = "pipico-program-requests"
}

resource "google_pubsub_subscription" "sub_pipico" {
  name                       = "pipico-program"
  topic                      = google_pubsub_topic.topic_pipico.name
  ack_deadline_seconds       = 10
  message_retention_duration = "600s"
}

resource "google_storage_bucket" "bucket_pipico" {
  name          = "pipico-artifacts-${var.project}"
  location      = "EUROPE-CENTRAL2"
  storage_class = "REGIONAL"
}

resource "google_logging_project_bucket_config" "name" {
  
}

resource "google_pubsub_subscription_iam_binding" "pipico_programmer_sub" {
  members      = ["serviceAccount:${google_service_account.sa_pipico_programmer.email}"]
  subscription = google_pubsub_subscription.sub_pipico.name
  role         = "roles/pubsub.subscriber"
  depends_on = [ google_service_account.sa_pipico_programmer, google_pubsub_subscription.sub_pipico ]
}

resource "google_storage_bucket_iam_binding" "pipico_programmer_artifacts" {
  members = ["serviceAccount:${google_service_account.sa_pipico_programmer.email}"]
  bucket  = google_storage_bucket.bucket_pipico.name
  role    = "roles/storage.objectViewer"
  depends_on = [ google_service_account.sa_pipico_programmer, google_storage_bucket.bucket_pipico ]
}

resource "google_project_iam_binding" "pipico_programmer_log" {
  project = var.project
  members = ["serviceAccount:${google_service_account.sa_pipico_programmer.email}"]
  role    = "roles/logging.logWriter"
  depends_on = [ google_service_account.sa_pipico_programmer ]
}
