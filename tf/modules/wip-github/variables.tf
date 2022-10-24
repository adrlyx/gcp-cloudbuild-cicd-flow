variable "google_project" {
  type = any
}

variable "attribute_mapping" {
  type = map(any)
  default = {
    "google.subject"       = "assertion.sub",
    "attribute.actor"      = "assertion.actor",
    "attribute.repository" = "assertion.repository"
  }
}

variable "issuer_uri" {
  type    = string
  default = "https://token.actions.githubusercontent.com"
}

variable "repo" {
  type = string
}