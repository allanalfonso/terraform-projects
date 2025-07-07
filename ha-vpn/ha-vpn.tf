# Configure the Cloud Routers
# Cloud Routers are the Control Plane

resource "google_compute_ha_vpn_gateway" "vpc-demo-vpn-gw1" {
  region  = "us-central1"
  name    = "vpc-demo-vpn-gw1"
  network = module.vpc-demo.network_name
}

resource "google_compute_ha_vpn_gateway" "on-prem-vpn-gw1" {
  region  = "us-central1"
  name    = "on-prem-vpn-gw1"
  network = module.on-prem.network_name
}

resource "google_compute_router" "vpc-demo-router1" {
  name    = "vpc-demo-router1"
  region  = "us-central1"
  network = module.vpc-demo.network_name
  bgp {
    asn = 64514
  }
}

resource "google_compute_router" "on-prem-router1" {
  name    = "on-prem-router1"
  region  = "us-central1"
  network = module.on-prem.network_name
  bgp {
    asn = 64515
  }
}

# Configure the VPN Tunnels
# VPN Tunnels are the Data Plane

resource "google_compute_vpn_tunnel" "vpc-demo-tunnel0" {
  name                  = "vpc-demo-tunnel0"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.vpc-demo-vpn-gw1.name
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.on-prem-vpn-gw1.name
  shared_secret         = "[SHARED_SECRET]"
  router                = google_compute_router.vpc-demo-router1.name
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "vpc-demo-tunnel1" {
  name                  = "vpc-demo-tunnel1"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.vpc-demo-vpn-gw1.name
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.on-prem-vpn-gw1.name
  shared_secret         = "[SHARED_SECRET]"
  router                = google_compute_router.vpc-demo-router1.name
  vpn_gateway_interface = 1
}

resource "google_compute_vpn_tunnel" "on-prem-tunnel0" {
  name                  = "on-prem-tunnel0"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.on-prem-vpn-gw1.name
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpc-demo-vpn-gw1.name
  shared_secret         = "[SHARED_SECRET]"
  router                = google_compute_router.on-prem-router1.name
  vpn_gateway_interface = 0
}

resource "google_compute_vpn_tunnel" "on-prem-tunnel1" {
  name                  = "on-prem-tunnel1"
  region                = "us-central1"
  vpn_gateway           = google_compute_ha_vpn_gateway.on-prem-vpn-gw1.name
  peer_gcp_gateway      = google_compute_ha_vpn_gateway.vpc-demo-vpn-gw1.name
  shared_secret         = "[SHARED_SECRET]"
  router                = google_compute_router.on-prem-router1.name
  vpn_gateway_interface = 1
}

# Configure BGP

resource "google_compute_router_interface" "vpc-demo-router1_interface1" {
  name       = "vpc-demo-router1-interface1"
  router     = google_compute_router.vpc-demo-router1.name
  region     = "us-central1"
  ip_range   = "169.254.0.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpc-demo-tunnel0.name
}

resource "google_compute_router_peer" "router1_peer1" {
  name                      = "vpc-demorouter1-peer1"
  router                    = google_compute_router.vpc-demo-router1.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.0.2"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.vpc-demo-router1_interface1.name
}

resource "google_compute_router_interface" "vpc-demo-router1_interface2" {
  name       = "vpc-demo-router1-interface2"
  router     = google_compute_router.vpc-demo-router1.name
  region     = "us-central1"
  ip_range   = "169.254.1.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.vpc-demo-tunnel1.name
}

resource "google_compute_router_peer" "vpc-demo-router1_peer2" {
  name                      = "vpc-demo-router1-peer2"
  router                    = google_compute_router.vpc-demo-router1.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.1.1"
  peer_asn                  = 64515
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.vpc-demo-router1_interface2.name
}

resource "google_compute_router_interface" "on-prem-router2_interface1" {
  name       = "on-prem-router2-interface1"
  router     = google_compute_router.on-prem-router1.name
  region     = "us-central1"
  ip_range   = "169.254.0.2/30"
  vpn_tunnel = google_compute_vpn_tunnel.on-prem-tunnel0.name
}

resource "google_compute_router_peer" "router2_peer1" {
  name                      = "on-prem-router2-peer1"
  router                    = google_compute_router.on-prem-router1.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.0.1"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.on-prem-router2_interface1.name
}

resource "google_compute_router_interface" "on-prem-router2_interface2" {
  name       = "on-prem-router2-interface2"
  router     = google_compute_router.on-prem-router1.name
  region     = "us-central1"
  ip_range   = "169.254.1.1/30"
  vpn_tunnel = google_compute_vpn_tunnel.on-prem-tunnel1.name
}

resource "google_compute_router_peer" "router2_peer2" {
  name                      = "on-prem-router2-peer2"
  router                    = google_compute_router.on-prem-router1.name
  region                    = "us-central1"
  peer_ip_address           = "169.254.1.2"
  peer_asn                  = 64514
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.on-prem-router2_interface2.name
}