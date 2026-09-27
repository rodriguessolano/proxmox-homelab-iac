output "master_ip" {
  value = module.master.ip_address
}

output "worker_ips" {
  value = [for w in module.worker : w.ip_address]
}

output "master_vmid" {
  value = module.master.vmid
}

output "worker_vmids" {
  value = [for w in module.worker : w.vmid]
}
