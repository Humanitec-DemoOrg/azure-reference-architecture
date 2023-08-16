variable "humanitec_credentials" {
  description = "The credentials for connecting to Humanitec."
  type = object({
    organization    = string
    token           = string
  })
  sensitive = true
}