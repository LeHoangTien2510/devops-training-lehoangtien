terraform {
  required_version = ">= 1.6"
  required_providers {
    random = { source = "hashicorp/random", version = "~> 3.6" }
    local  = { source = "hashicorp/local", version = "~> 2.5" }
  }
}

resource "random_pet" "name" { length = 3 }

resource "local_file" "hello" {
  filename = "${path.module}/out/hello-${random_pet.name.id}.txt"
  content  = "Hello from terraform, ${random_pet.name.id}!"
}

output "file_path" { value = local_file.hello.filename }
