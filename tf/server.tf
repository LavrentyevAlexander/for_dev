variable "do_token" {}
variable "lavrentyev_key_name" {}
variable "webserver" {}
variable "aws_my_access_key" {}
variable "aws_my_secret_key" {}

provider "aws" {
        region = "eu-west-1"
        access_key = "${var.aws_my_access_key}"
        secret_key = "${var.aws_my_secret_key}"
}

provider "digitalocean" {
        token = "${var.do_token}"
}

data "aws_route53_zone" "rebrain" {
        name = "devops.rebrain.srwx.net."
}

data "digitalocean_ssh_key" "LAVRENTYEV" {
                name = "${var.lavrentyev_key_name}"
        }

resource "random_password" "web_root_password" {
	count = 1
	length = 16
  	special = true
  	override_special = "_%@"
	upper = true
	lower = true
	number = true
}

resource "digitalocean_droplet" "webserver" {
        count = 1
        image  = "ubuntu-18-04-x64"
        name   = "${var.webserver}"
        region = "nyc1"
        size   = "s-1vcpu-1gb"
        ssh_keys = ["${data.digitalocean_ssh_key.LAVRENTYEV.fingerprint}"]

		provisioner "remote-exec" {
	        	inline = ["echo root:${element(random_password.web_root_password.*.result, count.index)} | chpasswd"]
		connection {
			host = "${self.ipv4_address}"
			type = "ssh"
			user = "root"
			private_key = "${file("/root/.ssh/id_rsa")}"
			}
		}
        	provisioner "local-exec" {
	                command = "echo ${self.name} ${self.ipv4_address} ${element(random_password.web_root_password.*.result, count.index)} >> devs.txt"
			}

}

resource "aws_route53_record" "aws_web" {
        count = 1
        zone_id = "${data.aws_route53_zone.rebrain.zone_id}"
        name = "${var.webserver}.devops.rebrain.srwx.net"
        type = "A"
        ttl = "300"
        records = ["${element(digitalocean_droplet.webserver.*.ipv4_address, count.index)}"]
}
