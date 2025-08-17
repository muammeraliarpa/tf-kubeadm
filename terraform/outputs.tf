output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker_public_ips" {
  value = [for w in aws_instance.worker : w.public_ip]
}

output "ssh_master" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.master.public_ip}"
  description = "Change the ip for workers."
}

