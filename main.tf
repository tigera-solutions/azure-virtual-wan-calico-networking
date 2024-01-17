terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    azapi = {
      source = "azure/azapi"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "azapi" {}

provider "azurerm" {
  features {}
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.credentials.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.credentials.kube_config.0.cluster_ca_certificate)
  }
}

data "azurerm_kubernetes_cluster" "credentials" {
  depends_on          = [azurerm_kubernetes_cluster.spoke_1_aks]
  name                = azurerm_kubernetes_cluster.spoke_1_aks.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azapi_resource" "vwan" {
  type      = "Microsoft.Network/virtualWans@2023-04-01"
  name      = "${var.resource_group_name}-vwan"
  location  = var.location
  parent_id = azurerm_resource_group.rg.id
  body = jsonencode({
    properties = {
      allowVnetToVnetTraffic = true
      type                   = "Standard"
    }
  })
}

resource "azapi_resource" "vhub" {
  type      = "Microsoft.Network/virtualHubs@2023-04-01"
  name      = "${var.resource_group_name}-vhub"
  location  = var.location
  parent_id = azurerm_resource_group.rg.id
  body = jsonencode({
    properties = {
      addressPrefix = var.vwan_hub_address_space
      sku           = "Standard"
      virtualWan = {
        id = azapi_resource.vwan.id
      }
    }
  })
}

resource "azapi_resource" "vhub_connections" {
  type      = "Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-04-01"
  name      = "${var.resource_group_name}-vhub-connections"
  parent_id = azapi_resource.vhub.id
  body = jsonencode({
    properties = {
      allowHubToRemoteVnetTransit         = true
      allowRemoteVnetToUseHubVnetGateways = false
      enableInternetSecurity              = false
      remoteVirtualNetwork = {
        id = azurerm_virtual_network.spoke_1_vnet.id
      }
    }
  })
}

resource "azapi_resource" "vhub-bgpconnection-1" {
  type      = "Microsoft.Network/virtualHubs/bgpConnections@2023-04-01"
  name      = "${var.resource_group_name}-vhub-bgpconnection-1"
  parent_id = azapi_resource.vhub.id
  body = jsonencode({
    properties = {
      hubVirtualNetworkConnection = {
        id = azapi_resource.vhub_connections.id
      }
      peerAsn = var.vwan_hub_bgpconnection_asn
      peerIp  = var.vwan_hub_bgpconnection_1_peer_ip
    }
  })
  depends_on = [azapi_resource.vhub_connections]
}

resource "azapi_resource" "vhub-bgpconnection-2" {
  type      = "Microsoft.Network/virtualHubs/bgpConnections@2023-04-01"
  name      = "${var.resource_group_name}-vhub-bgpconnection-2"
  parent_id = azapi_resource.vhub.id
  body = jsonencode({
    properties = {
      hubVirtualNetworkConnection = {
        id = azapi_resource.vhub_connections.id
      }
      peerAsn = var.vwan_hub_bgpconnection_asn
      peerIp  = var.vwan_hub_bgpconnection_2_peer_ip
    }
  })
  depends_on = [azapi_resource.vhub-bgpconnection-1]
}

resource "azurerm_virtual_network" "spoke_1_vnet" {
  name                = "${var.resource_group_name}-spoke-1-vnet"
  address_space       = var.spoke_1_vnet_address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "spoke_1_subnet" {
  name                 = "${var.resource_group_name}-spoke-1-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_1_vnet.name
  address_prefixes     = var.spoke_1_subnet_address_prefixes
}

data "azurerm_kubernetes_service_versions" "current" {
  location       = var.location
  version_prefix = var.kubernetes_version
}

resource "azurerm_kubernetes_cluster" "spoke_1_aks" {
  name                    = "${var.resource_group_name}-spoke-1-aks"
  location                = var.location
  resource_group_name     = azurerm_resource_group.rg.name
  kubernetes_version      = data.azurerm_kubernetes_service_versions.current.latest_version
  private_cluster_enabled = false
  dns_prefix              = "aks"

  default_node_pool {
    name           = "default"
    node_count     = var.aks_nodepool_nodes_count
    vm_size        = var.aks_nodepool_vm_size
    vnet_subnet_id = azurerm_subnet.spoke_1_subnet.id
    type           = "VirtualMachineScaleSets"
    node_labels = {
      route-reflector = true
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "none"
    service_cidr   = var.aks_service_cidr
    dns_service_ip = var.aks_dns_service_ip
  }
}

resource "helm_release" "calico" {
  name             = "calico"
  chart            = "tigera-operator"
  repository       = "https://docs.projectcalico.org/charts"
  version          = var.calico_version
  namespace        = "tigera-operator"
  create_namespace = true
  values = [templatefile("${path.module}/helm_values/values-calico.yaml", {
    pod_cidr     = "${var.calico_pod_cidr}"
    calico_encap = "VXLAN"
  })]

  depends_on = [azurerm_kubernetes_cluster.spoke_1_aks]
}
