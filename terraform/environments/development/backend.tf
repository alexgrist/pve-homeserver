terraform {
  # Local state is the default for a single operator. Use the documented B2
  # backend file when remote state and locking are required.
  backend "local" {
    path = "terraform.tfstate"
  }
}
