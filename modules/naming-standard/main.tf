locals {
  # Utilise the last 6 digits of the subscription ID to make the name unique
  subId = substr(var.subId, -6, 6)
}