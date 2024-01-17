variable "location" {
  description = "The resource group location"
  default     = "eastus"
}

variable "resource_group_name" {
  description = "The resource group name to be created"
  default     = "sabo-vwan"
}

variable "vwan_hub_address_space" {
  description = "VWAN hub address space"
  default     = "10.0.0.0/22"
}

variable "vwan_hub_bgpconnection_asn" {
  description = "A 16 bit Autonomous System Number that can't be in the range between 65515 and 65520, inclusively."
  default     = 65521
}

variable "vwan_hub_bgpconnection_1_peer_ip" {
  description = "VWAN Virtual Hub peer ip"
  default     = "10.0.4.4"
}

variable "vwan_hub_bgpconnection_2_peer_ip" {
  description = "VWAN Virtual Hub peer ip"
  default     = "10.0.4.5"
}

variable "spoke_1_vnet_address_space" {
  description = "Spoke1 VNET address space"
  default     = ["10.0.4.0/22"]
}

variable "spoke_1_subnet_address_prefixes" {
  description = "Spoke1 VNET subnet address prefixes"
  default     = ["10.0.4.0/22"]
}

variable "aks_nodepool_nodes_count" {
  description = "Default nodepool nodes count"
  default     = 2
}

variable "aks_nodepool_vm_size" {
  description = "Default nodepool VM size"
  default     = "Standard_D2_v2"
}

variable "aks_dns_service_ip" {
  description = "CNI DNS service IP"
  default     = "10.0.8.10"
}

variable "aks_service_cidr" {
  description = "CNI service cidr"
  default     = "10.0.8.0/22"
}

variable "calico_pod_cidr" {
  description = "Calico POD CIDR"
  type        = string
  default     = "10.0.12.0/22"
}

variable "calico_version" {
  description = "Calico Open Source release version"
  type        = string
  default     = "3.26.4"
}

variable "kubernetes_version" {
  description = "AKS Kubernetes version"
  type        = string
  default     = "1.27"
}
