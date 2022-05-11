require("dotenv").config();
const tfxjs = require("tfxjs");
const tfx = new tfxjs("./patterns/edge-vpc", "ibmcloud_api_key", {
  quiet: true,
});
const aclRulesVsi = require("./acl-rules-vsi.json");
const tags = ["acceptance-test", "landing-zone"];

tfx.plan("LandingZone VSI Pattern", () => {
  tfx.module(
    "Root Module",
    "module.acceptance_tests.module.landing-zone",
    tfx.resource(
      "Activity Tracker Route",
      "ibm_atracker_route.atracker_route[0]",
      {
        name: "at-test-atracker-route",
        receive_global_events: true,
      }
    ),
    tfx.resource(
      "Activity Tracker Target",
      "ibm_atracker_target.atracker_target",
      {
        cos_endpoint: [
          {
            bucket: "at-test-atracker-bucket",
            endpoint:
              "s3.private.us-south.cloud-object-storage.appdomain.cloud",
          },
        ],
        target_type: "cloud_object_storage",
        name: "at-test-atracker",
      }
    ),
    tfx.resource(
      "Workload Object Storage Bucket",
      `ibm_cos_bucket.buckets[\"workload-bucket\"]`,
      {
        bucket_name: "at-test-workload-bucket",
        endpoint_type: "public",
        force_delete: true,
        region_location: "us-south",
        retention_rule: [],
        storage_class: "standard",
      }
    ),
    tfx.resource(
      "Management Object Storage Bucket",
      `ibm_cos_bucket.buckets[\"management-bucket\"]`,
      {
        bucket_name: "at-test-management-bucket",
        endpoint_type: "public",
        force_delete: true,
        region_location: "us-south",
        retention_rule: [],
        storage_class: "standard",
      }
    ),
    tfx.resource(
      "Edge Object Storage Bucket",
      `ibm_cos_bucket.buckets[\"edge-bucket\"]`,
      {
        bucket_name: "at-test-edge-bucket",
        endpoint_type: "public",
        force_delete: true,
        region_location: "us-south",
        retention_rule: [],
        storage_class: "standard",
      }
    ),
    tfx.resource(
      "Activity Tracker Object Storage Bucket",
      `ibm_cos_bucket.buckets[\"atracker-bucket\"]`,
      {
        bucket_name: "at-test-atracker-bucket",
        endpoint_type: "public",
        force_delete: true,
        region_location: "us-south",
        retention_rule: [],
        storage_class: "standard",
      }
    ),
    tfx.resource(
      "IAM Policy Flow Logs to Atracker Object Storage",
      `ibm_iam_authorization_policy.policy[\"flow-logs-atracker-cos-cos\"]`,
      {
        description:
          "Allow flow logs write access cloud object storage instance",
        roles: ["Writer"],
        source_resource_type: "flow-log-collector",
        source_service_name: "is",
        target_service_name: "cloud-object-storage",
      }
    ),
    tfx.resource(
      "IAM Policy Atracker Object Storage to Key Managemnet",
      `ibm_iam_authorization_policy.policy[\"cos-cos-to-key-management\"]`,
      {
        description: "Allow COS instance to read from KMS instance",
        roles: ["Reader"],
        source_service_name: "cloud-object-storage",
        target_service_name: "kms",
      }
    ),
    tfx.resource(
      "IAM Policy Atracker Object Storage to Key Managemnet",
      `ibm_iam_authorization_policy.policy[\"cos-atracker-cos-to-key-management\"]`,
      {
        description: "Allow COS instance to read from KMS instance",
        roles: ["Reader"],
        source_service_name: "cloud-object-storage",
        target_service_name: "kms",
      }
    ),
    tfx.resource(
      "IAM Policy Flow Logs to Object Storage",
      `ibm_iam_authorization_policy.policy[\"flow-logs-cos-cos\"]`,
      {
        description:
          "Allow flow logs write access cloud object storage instance",
        roles: ["Writer"],
        source_resource_type: "flow-log-collector",
        source_service_name: "is",
        target_service_name: "cloud-object-storage",
      }
    ),
    tfx.resource(
      "IAM Policy Management Resource Group to Block Storage",
      'ibm_iam_authorization_policy.policy["block-storage"]',
      {
        description:
          "Allow block storage volumes to be encrypted by KMS instance",
        roles: ["Reader"],
        source_service_name: "server-protect",
        target_service_name: "kms",
      }
    ),
    tfx.resource(
      "Flow Logs for Edge VPC",
      'ibm_is_flow_log.flow_logs["edge"]',
      {
        active: true,
        name: "edge-logs",
        storage_bucket: "at-test-edge-bucket",
      }
    ),
    tfx.resource(
      "Flow Logs for Management VPC",
      'ibm_is_flow_log.flow_logs["management"]',
      {
        active: true,
        name: "management-logs",
        storage_bucket: "at-test-management-bucket",
      }
    ),
    tfx.resource(
      "Flow Logs for Workload VPC",
      'ibm_is_flow_log.flow_logs["workload"]',
      {
        active: true,
        name: "workload-logs",
        storage_bucket: "at-test-workload-bucket",
      }
    ),
    tfx.resource(
      "Virtual Endpoint Gateway Object Storage for Edge VPC",
      'ibm_is_virtual_endpoint_gateway.endpoint_gateway["edge-cos"]',
      {
        name: "at-test-edge-cos",
        target: [
          {
            crn: "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.us-south.cloud-object-storage.appdomain.cloud",
            name: null,
            resource_type: "provider_cloud_service",
          },
        ],
      }
    ),
    tfx.resource(
      "Virtual Endpoint Gateway Object Storage for Management VPC",
      'ibm_is_virtual_endpoint_gateway.endpoint_gateway["management-cos"]',
      {
        name: "at-test-management-cos",
        target: [
          {
            crn: "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.us-south.cloud-object-storage.appdomain.cloud",
            name: null,
            resource_type: "provider_cloud_service",
          },
        ],
      }
    ),
    tfx.resource(
      "Virtual Endpoint Gateway Object Storage for Workload VPC",
      'ibm_is_virtual_endpoint_gateway.endpoint_gateway["workload-cos"]',
      {
        name: "at-test-workload-cos",
        target: [
          {
            crn: "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.us-south.cloud-object-storage.appdomain.cloud",
            name: null,
            resource_type: "provider_cloud_service",
          },
        ],
      }
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Edge VPC Zone 1",
      'ibm_is_subnet_reserved_ip.ip["edge-cos-gateway-vpe-zone-1-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Edge VPC Zone 2",
      'ibm_is_subnet_reserved_ip.ip["edge-cos-gateway-vpe-zone-2-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Edge VPC Zone 3",
      'ibm_is_subnet_reserved_ip.ip["edge-cos-gateway-vpe-zone-3-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Management VPC Zone 1",
      'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-1-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Management VPC Zone 2",
      'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-2-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Management VPC Zone 3",
      'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-3-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Workload VPC Zone 1",
      'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-1-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Workload VPC Zone 2",
      'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-2-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway for Object Storage Reserved IP Workload VPC Zone 3",
      'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-3-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Edge COS Zone 1",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["edge-cos-gateway-vpe-zone-1-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Edge COS Zone 2",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["edge-cos-gateway-vpe-zone-2-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Edge COS Zone 3",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["edge-cos-gateway-vpe-zone-3-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Management COS Zone 1",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["management-cos-gateway-vpe-zone-1-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Management COS Zone 2",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["management-cos-gateway-vpe-zone-2-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Management COS Zone 3",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["management-cos-gateway-vpe-zone-3-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Workload COS Zone 1",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["workload-cos-gateway-vpe-zone-1-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Workload COS Zone 2",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["workload-cos-gateway-vpe-zone-2-ip"]',
      {}
    ),
    tfx.resource(
      "Endpoint Gateway IP For Workload COS Zone 3",
      'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["workload-cos-gateway-vpe-zone-3-ip"]',
      {}
    ),
    tfx.resource(
      "Resource Groups Edge",
      'ibm_resource_group.resource_groups["at-test-edge-rg"]',
      {
        name: "at-test-edge-rg",
      }
    ),
    tfx.resource(
      "Resource Groups Managment",
      'ibm_resource_group.resource_groups["at-test-management-rg"]',
      {
        name: "at-test-management-rg",
      }
    ),
    tfx.resource(
      "Resource Groups",
      'ibm_resource_group.resource_groups["at-test-service-rg"]',
      {
        name: "at-test-service-rg",
      }
    ),
    tfx.resource(
      "Resource Groups Workload",
      'ibm_resource_group.resource_groups["at-test-workload-rg"]',
      {
        name: "at-test-workload-rg",
      }
    ),
    tfx.resource(
      "Cloud Object Storage Instance Atracker",
      'ibm_resource_instance.cos["atracker-cos"]',
      {
        location: "global",
        name: "at-test-atracker-cos",
        plan: "standard",
        service: "cloud-object-storage",
        tags: tags,
      }
    ),
    tfx.resource(
      "Cloud Object Storage Instance",
      'ibm_resource_instance.cos["cos"]',
      {
        location: "global",
        name: "at-test-cos",
        plan: "standard",
        service: "cloud-object-storage",
        tags: tags,
      }
    ),
    tfx.resource(
      "Cloud Object Storage Bind Resource Key",
      'ibm_resource_key.key["cos-bind-key"]',
      {
        name: "at-test-cos-bind-key",
        role: "Writer",
        tags: tags,
      }
    ),
    tfx.resource(
      "Transit Gateway Connection Edge",
      'ibm_tg_connection.connection["edge"]',
      {
        name: "at-test-edge-hub-connection",
        network_type: "vpc",
        timeouts: { create: "30m", delete: "30m", update: null },
      }
    ),
    tfx.resource(
      "Transit Gateway Connection Management",
      'ibm_tg_connection.connection["management"]',
      {
        name: "at-test-management-hub-connection",
        network_type: "vpc",
        timeouts: { create: "30m", delete: "30m", update: null },
      }
    ),
    tfx.resource(
      "Transit Gateway Connection Workload",
      'ibm_tg_connection.connection["workload"]',
      {
        name: "at-test-workload-hub-connection",
        network_type: "vpc",
        timeouts: { create: "30m", delete: "30m", update: null },
      }
    ),
    tfx.resource("Transit Gateway", "ibm_tg_gateway.transit_gateway[0]", {
      global: false,
      location: "us-south",
      name: "at-test-transit-gateway",
      timeouts: { create: "30m", delete: "30m", update: null },
    })
  );

  tfx.module(
    "Key Management Module",
    "module.acceptance_tests.module.landing-zone.module.key_management",
    tfx.resource(
      "Landing Zone Key Management Atracker",
      'ibm_kms_key.key["at-test-atracker-key"]',
      {
        force_delete: true,
        key_name: "at-test-atracker-key",
        key_ring_id: "at-test-slz-ring",
        standard_key: false,
      }
    ),
    tfx.resource(
      "Landing Zone Key Management VSI Volume",
      'ibm_kms_key.key["at-test-vsi-volume-key"]',
      {
        force_delete: true,
        key_name: "at-test-vsi-volume-key",
        key_ring_id: "at-test-slz-ring",
        standard_key: false,
      }
    ),
    tfx.resource(
      "Landing Zone Key Management Ring",
      'ibm_kms_key_rings.rings["at-test-slz-ring"]',
      {
        key_ring_id: "at-test-slz-ring",
      }
    ),
    tfx.resource(
      "Landing Zone Key Management Test Key",
      'ibm_kms_key.key["at-test-slz-key"]',
      {
        force_delete: true,
        key_name: "at-test-slz-key",
        key_ring_id: "at-test-slz-ring",
        standard_key: false,
      }
    ),
    tfx.resource(
      "Landing Zone Key Managment Resource Instance",
      "ibm_resource_instance.kms[0]",
      {
        location: "us-south",
        name: "at-test-slz-kms",
        plan: "tiered-pricing",
        service: "kms",
      }
    )
  );

  tfx.module(
    "SSH Key Module",
    "module.acceptance_tests.module.landing-zone.module.ssh_keys",
    tfx.resource("Landing Zone SSH Key", 'ibm_is_ssh_key.ssh_key["ssh-key"]', {
      name: "at-test-ssh-key",
      public_key: "<user defined>",
      tags: tags,
    })
  );
  tfx.module(
    "Edge Virtual Private Cloud",
    'module.acceptance_tests.module.landing-zone.module.vpc["edge"]',
    tfx.resource(
      "Virtual Private Cloud Edge ACL",
      'ibm_is_network_acl.network_acl["edge-acl"]',
      {
        name: "at-test-edge-edge-acl",
        rules: aclRulesVsi.management,
      }
    ),
    tfx.resource("Virtual Private Cloud Management", "ibm_is_vpc.vpc", {
      address_prefix_management: "manual",
      classic_access: false,
      name: "at-test-edge-vpc",
    }),
    tfx.resource(
      "Edge Zone 1 Prefix",
      'ibm_is_vpc_address_prefix.address_prefixes[\"at-test-edge-zone-1-1\"]',
      {
        "cidr": "10.5.0.0/16",
        "is_default": false,
        "name": "at-test-edge-zone-1-1",
        "zone": "us-south-1"
      }
    ),
    tfx.resource(
      "Edge Zone 2 Prefix",
      'ibm_is_vpc_address_prefix.address_prefixes[\"at-test-edge-zone-2-1\"]',
      {
        "cidr": "10.6.0.0/16",
        "is_default": false,
        "name": "at-test-edge-zone-2-1",
        "zone": "us-south-2"
      }
    ),
    tfx.resource(
      "Edge Zone 3 Prefix",
      'ibm_is_vpc_address_prefix.address_prefixes[\"at-test-edge-zone-3-1\"]',
      {
        "cidr": "10.7.0.0/16",
        "is_default": false,
        "name": "at-test-edge-zone-3-1",
        "zone": "us-south-3"
      }
    ),
    tfx.resource(
      "Edge Subnet VPN 1 Zone 1",
      'ibm_is_subnet.subnet["at-test-edge-vpn-1-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.5.10.0/24",
        name: "at-test-edge-vpn-1-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Edge Subnet VPN 1 Zone 2",
      'ibm_is_subnet.subnet["at-test-edge-vpn-1-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.6.10.0/24",
        name: "at-test-edge-vpn-1-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Edge Subnet VPN 1 Zone 3",
      'ibm_is_subnet.subnet["at-test-edge-vpn-1-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.7.10.0/24",
        name: "at-test-edge-vpn-1-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Edge Subnet VPN 2 Zone 1",
      'ibm_is_subnet.subnet["at-test-edge-vpn-2-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.5.20.0/24",
        name: "at-test-edge-vpn-2-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Edge Subnet VPN 2 Zone 2",
      'ibm_is_subnet.subnet["at-test-edge-vpn-2-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.6.20.0/24",
        name: "at-test-edge-vpn-2-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Edge Subnet VPN 2 Zone 3",
      'ibm_is_subnet.subnet["at-test-edge-vpn-2-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.7.20.0/24",
        name: "at-test-edge-vpn-2-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-external Zone 1",
      'ibm_is_subnet.subnet["at-test-edge-f5-external-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.5.30.0/24",
        name: "at-test-edge-f5-external-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-external Zone 2",
      'ibm_is_subnet.subnet["at-test-edge-f5-external-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.6.30.0/24",
        name: "at-test-edge-f5-external-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-external Zone 3",
      'ibm_is_subnet.subnet["at-test-edge-f5-external-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.7.30.0/24",
        name: "at-test-edge-f5-external-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-management Zone 1",
      'ibm_is_subnet.subnet["at-test-edge-f5-management-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.5.40.0/24",
        name: "at-test-edge-f5-management-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-management Zone 2",
      'ibm_is_subnet.subnet["at-test-edge-f5-management-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.6.40.0/24",
        name: "at-test-edge-f5-management-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-management Zone 3",
      'ibm_is_subnet.subnet["at-test-edge-f5-management-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.7.40.0/24",
        name: "at-test-edge-f5-management-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-workload Zone 1",
      'ibm_is_subnet.subnet["at-test-edge-f5-workload-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.5.50.0/24",
        name: "at-test-edge-f5-workload-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-workload Zone 2",
      'ibm_is_subnet.subnet["at-test-edge-f5-workload-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.6.50.0/24",
        name: "at-test-edge-f5-workload-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-workload Zone 3",
      'ibm_is_subnet.subnet["at-test-edge-f5-workload-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.7.50.0/24",
        name: "at-test-edge-f5-workload-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-bastion Zone 1",
      'ibm_is_subnet.subnet["at-test-edge-f5-bastion-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.5.60.0/24",
        name: "at-test-edge-f5-bastion-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-bastion Zone 2",
      'ibm_is_subnet.subnet["at-test-edge-f5-bastion-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.6.60.0/24",
        name: "at-test-edge-f5-bastion-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Edge Subnet f5-bastion Zone 3",
      'ibm_is_subnet.subnet["at-test-edge-f5-bastion-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.7.60.0/24",
        name: "at-test-edge-f5-bastion-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Edge Subnet bastion Zone 1",
      'ibm_is_subnet.subnet["at-test-edge-bastion-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.5.70.0/24",
        name: "at-test-edge-bastion-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Edge Subnet bastion Zone 2",
      'ibm_is_subnet.subnet["at-test-edge-bastion-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.6.70.0/24",
        name: "at-test-edge-bastion-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Edge Subnet bastion Zone 3",
      'ibm_is_subnet.subnet["at-test-edge-bastion-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.7.70.0/24",
        name: "at-test-edge-bastion-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Edge Subnet VPE Zone 1",
      'ibm_is_subnet.subnet["at-test-edge-vpe-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.5.80.0/24",
        name: "at-test-edge-vpe-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Edge Subnet VPE Zone 2",
      'ibm_is_subnet.subnet["at-test-edge-vpe-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.6.80.0/24",
        name: "at-test-edge-vpe-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Edge Subnet VPE Zone 3",
      'ibm_is_subnet.subnet["at-test-edge-vpe-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.7.80.0/24",
        name: "at-test-edge-vpe-zone-3",
        zone: "us-south-3",
      }
    ),
  );
  tfx.module(
    "Management Virtual Private Cloud",
    'module.acceptance_tests.module.landing-zone.module.vpc["management"]',
    tfx.resource(
      "Virtual Private Cloud Management ACL",
      'ibm_is_network_acl.network_acl["management-acl"]',
      {
        name: "at-test-management-management-acl",
        rules: aclRulesVsi.management,
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Managment Subnet VPE Zone 1",
      'ibm_is_subnet.subnet["at-test-management-vpe-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.10.20.0/24",
        name: "at-test-management-vpe-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet VPE Zone 2",
      'ibm_is_subnet.subnet["at-test-management-vpe-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.20.20.0/24",
        name: "at-test-management-vpe-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet VPE Zone 3",
      'ibm_is_subnet.subnet["at-test-management-vpe-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.30.20.0/24",
        name: "at-test-management-vpe-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet VSI Zone 1",
      'ibm_is_subnet.subnet["at-test-management-vsi-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.10.10.0/24",
        name: "at-test-management-vsi-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet VSI Zone 2",
      'ibm_is_subnet.subnet["at-test-management-vsi-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.20.10.0/24",
        name: "at-test-management-vsi-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet VSI Zone 3",
      'ibm_is_subnet.subnet["at-test-management-vsi-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.30.10.0/24",
        name: "at-test-management-vsi-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource("Virtual Private Cloud Management", "ibm_is_vpc.vpc", {
      address_prefix_management: "manual",
      classic_access: false,
      name: "at-test-management-vpc",
    }),
    tfx.resource(
      "Virtual Private Cloud Management Subnet Address Prefix VPE",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vpe-zone-1"]',
      {
        cidr: "10.10.20.0/24",
        is_default: false,
        name: "at-test-management-vpe-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet Address Prefix VPE",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vpe-zone-2"]',
      {
        cidr: "10.20.20.0/24",
        is_default: false,
        name: "at-test-management-vpe-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet Address Prefix VPE",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vpe-zone-3"]',
      {
        cidr: "10.30.20.0/24",
        is_default: false,
        name: "at-test-management-vpe-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet Address Prefix VSI",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vsi-zone-1"]',
      {
        cidr: "10.10.10.0/24",
        is_default: false,
        name: "at-test-management-vsi-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet Address Prefix VSI",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vsi-zone-2"]',
      {
        cidr: "10.20.10.0/24",
        is_default: false,
        name: "at-test-management-vsi-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Management Subnet Address Prefix VSI",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vsi-zone-3"]',
      {
        cidr: "10.30.10.0/24",
        is_default: false,
        name: "at-test-management-vsi-zone-3",
        zone: "us-south-3",
      }
    )
  );
  tfx.module(
    "Workload Virtual Private Cloud",
    'module.acceptance_tests.module.landing-zone.module.vpc["workload"]',
    tfx.resource(
      "Virtual Private Cloud Workload ACL",
      'ibm_is_network_acl.network_acl["workload-acl"]',
      {
        name: "at-test-workload-workload-acl",
        rules: aclRulesVsi.workload,
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet VPE Zone 1",
      'ibm_is_subnet.subnet["at-test-workload-vpe-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.40.20.0/24",
        name: "at-test-workload-vpe-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet VPE Zone 2",
      'ibm_is_subnet.subnet["at-test-workload-vpe-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.50.20.0/24",
        name: "at-test-workload-vpe-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet VPE Zone 3",
      'ibm_is_subnet.subnet["at-test-workload-vpe-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.60.20.0/24",
        name: "at-test-workload-vpe-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet VSI Zone 1",
      'ibm_is_subnet.subnet["at-test-workload-vsi-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.40.10.0/24",
        name: "at-test-workload-vsi-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet VSI Zone 2",
      'ibm_is_subnet.subnet["at-test-workload-vsi-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.50.10.0/24",
        name: "at-test-workload-vsi-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet VSI Zone 3",
      'ibm_is_subnet.subnet["at-test-workload-vsi-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.60.10.0/24",
        name: "at-test-workload-vsi-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource("Virtual Private Cloud Workload", "ibm_is_vpc.vpc", {
      address_prefix_management: "manual",
      classic_access: false,
      name: "at-test-workload-vpc",
    }),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet Address Prefix VPE",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vpe-zone-1"]',
      {
        cidr: "10.40.20.0/24",
        is_default: false,
        name: "at-test-workload-vpe-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet Address Prefix VPE",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vpe-zone-2"]',
      {
        cidr: "10.50.20.0/24",
        is_default: false,
        name: "at-test-workload-vpe-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet Address Prefix VPE",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vpe-zone-3"]',
      {
        cidr: "10.60.20.0/24",
        is_default: false,
        name: "at-test-workload-vpe-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet Address Prefix VSI",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vsi-zone-1"]',
      {
        cidr: "10.40.10.0/24",
        is_default: false,
        name: "at-test-workload-vsi-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet Address Prefix VSI",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vsi-zone-2"]',
      {
        cidr: "10.50.10.0/24",
        is_default: false,
        name: "at-test-workload-vsi-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Virtual Private Cloud Workload Subnet Address Prefix VSI",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vsi-zone-3"]',
      {
        cidr: "10.60.10.0/24",
        is_default: false,
        name: "at-test-workload-vsi-zone-3",
        zone: "us-south-3",
      }
    )
  );
  tfx.module(
    "Virtual Server Instance",
    'module.acceptance_tests.module.landing-zone.module.vsi["at-test-management-server"]',
    [
      tfx.resource(
        "Virtual Server Instance Management Server 1",
        'ibm_is_instance.vsi["at-test-management-server-1"]',
        {
          force_action: false,
          image: "r006-35668c13-c034-43b2-b0a1-2994b9044cec",
          name: "at-test-management-server-1",
          profile: "cx2-4x8",
          wait_before_delete: true,
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Virtual Server Instance Management Server 2",
        'ibm_is_instance.vsi["at-test-management-server-2"]',
        {
          force_action: false,
          image: "r006-35668c13-c034-43b2-b0a1-2994b9044cec",
          name: "at-test-management-server-2",
          profile: "cx2-4x8",
          wait_before_delete: true,
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Virtual Server Instance Management Server 3",
        'ibm_is_instance.vsi["at-test-management-server-3"]',
        {
          force_action: false,
          image: "r006-35668c13-c034-43b2-b0a1-2994b9044cec",
          name: "at-test-management-server-3",
          profile: "cx2-4x8",
          wait_before_delete: true,
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Virtual Server Instance Security Group",
        'ibm_is_security_group.security_group["management"]',
        {
          name: "management",
        }
      ),
      tfx.resource(
        "Virtual Server Instance Security Group Rules Inbound",
        'ibm_is_security_group_rule.security_group_rules["management-allow-ibm-inbound"]',
        {
          direction: "inbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "161.26.0.0/16",
          tcp: [],
          udp: [],
        }
      ),
      tfx.resource(
        "Virtual Server Instance Security Group Rules Inbound",
        'ibm_is_security_group_rule.security_group_rules["management-allow-vpc-inbound"]',
        {
          direction: "inbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "10.0.0.0/8",
          tcp: [],
          udp: [],
        }
      ),
      tfx.resource(
        "Virtual Server Instance Security Group Rules Outbound",
        'ibm_is_security_group_rule.security_group_rules["management-allow-ibm-tcp-443-outbound"]',
        {
          direction: "outbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "161.26.0.0/16",
          tcp: [
            {
              port_max: 443,
              port_min: 443,
            },
          ],
          udp: [],
        }
      ),
      tfx.resource(
        "Virtual Server Instance Security Group Rules Outbound",
        'ibm_is_security_group_rule.security_group_rules["management-allow-ibm-tcp-53-outbound"]',
        {
          direction: "outbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "161.26.0.0/16",
          tcp: [
            {
              port_max: 53,
              port_min: 53,
            },
          ],
          udp: [],
        }
      ),
      tfx.resource(
        "Virtual Server Instance Security Group Rules Outbound",
        'ibm_is_security_group_rule.security_group_rules["management-allow-ibm-tcp-80-outbound"]',
        {
          direction: "outbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "161.26.0.0/16",
          tcp: [
            {
              port_max: 80,
              port_min: 80,
            },
          ],
          udp: [],
        }
      ),
      tfx.resource(
        "Virtual Server Instance Security Group Rules Outbound",
        'ibm_is_security_group_rule.security_group_rules["management-allow-vpc-outbound"]',
        {
          direction: "outbound",
          icmp: [],
          ip_version: "ipv4",
          remote: "10.0.0.0/8",
          tcp: [],
          udp: [],
        }
      ),
    ]
  );
});
