data "external" "env" {
  program = ["${path.module}/locals-from-env.sh"]

  # For Windows (or Powershell core on MacOS and Linux),
  # run a Powershell script instead
  #program = ["${path.module}/env.ps1"]
}

locals {
    public_ssh_key = var.public_ssh_key!="" ? var.public_ssh_key : data.external.env.result["public_ssh_key"]
}
