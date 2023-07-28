terraform {
  cloud {
    organization = "mtc-terraform-ansible-jenkins"

    workspaces {
      name = "terraform-ansible-jenkins"
    }
  }
}