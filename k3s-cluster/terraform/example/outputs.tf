output "k3s_master_ip" {
  value = module.k3s_cluster.master_ip
}

output "k3s_worker_ips" {
  value = module.k3s_cluster.worker_ips
}

output "kubeconfig_hint" {
  description = "Como puxar o kubeconfig do master pra sua máquina"
  value       = "ssh debian@${module.k3s_cluster.master_ip} sudo cat /etc/rancher/k3s/k3s.yaml"
}
