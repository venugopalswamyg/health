/*
 Minimal Cloud SQL (Postgres) skeleton for private IP.
*/
resource "google_sql_database_instance" "postgres" {
  name             = var.instance_name
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier = var.tier
    ip_configuration {
      ipv4_enabled = false
      private_network = var.network_self_link
      require_ssl = true
    }
  }
}

resource "google_sql_database" "db" {
  instance = google_sql_database_instance.postgres.name
  name     = var.database_name
}
