require("dotenv").config();
const tfxjs = require("tfxjs");
const tfx = new tfxjs("./patterns/mixed", "ibmcloud_api_key", { quiet: true });
const aclRules = require("./acl-rules.json");
const tags = ["acceptance-test", "landing-zone"];

tfx.plan("LandingZone Mixed Pattern", () => {
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
    tfx.resource("Random COS Suffix", "random_string.random_cos_suffix", {
      length: 8,
    }),
    tfx.resource(
      "Activity Tracker Target",
      "ibm_atracker_target.atracker_target[0]",
      {
        cos_endpoint: [
          {
            endpoint:
              "s3.private.us-south.cloud-object-storage.appdomain.cloud",
            service_to_service_enabled: null,
          },
        ],
        target_type: "cloud_object_storage",
        name: "at-test-atracker",
      }
    ),
    tfx.resource(
      "Workload Cluster",
      `ibm_container_vpc_cluster.cluster[\"at-test-workload-cluster\"]`,
      {
        disable_public_service_endpoint: true,
        flavor: "bx2.16x64",
        kube_version: function (value) {
          return {
            appendMessage: "to contain _openshift. Got " + value,
            expectedData: value.indexOf("_openshift") !== -1,
          };
        },
        name: "at-test-workload-cluster",
        tags: ["acceptance-test", "landing-zone"],
        timeouts: { create: "3h", delete: "2h", update: "3h" },
        wait_till: "IngressReady",
        worker_count: 1,
        zones: [
          { name: "us-south-1" },
          { name: "us-south-2" },
          { name: "us-south-3" },
        ],
      }
    ),
    tfx.resource(
      "Workload Cluster Logging Pool",
      `ibm_container_vpc_worker_pool.pool[\"at-test-workload-cluster-logging-worker-pool\"]`,
      {
        flavor: "bx2.16x64",
        worker_count: 1,
        worker_pool_name: "logging-worker-pool",
        zones: [
          { name: "us-south-1" },
          { name: "us-south-2" },
          { name: "us-south-3" },
        ],
      }
    ),
    tfx.resource(
      "Activity Tracker Object Storage Bucket",
      `ibm_cos_bucket.buckets[\"atracker-bucket\"]`,
      {
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
        endpoint_type: "public",
        force_delete: true,
        region_location: "us-south",
        retention_rule: [],
        storage_class: "standard",
      }
    ),
    tfx.resource(
      "Workload Object Storage Bucket",
      `ibm_cos_bucket.buckets[\"workload-bucket\"]`,
      {
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
      "IAM Policy Atracker Object Storage to Key management",
      `ibm_iam_authorization_policy.policy[\"cos-cos-to-key-management\"]`,
      {
        description: "Allow COS instance to read from KMS instance",
        roles: ["Reader"],
        source_service_name: "cloud-object-storage",
        target_service_name: "kms",
      }
    ),
    tfx.resource(
      "IAM Policy Atracker Object Storage to Key management",
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
      "Management VPC Flow Logs",
      'ibm_is_flow_log.flow_logs["management"]',
      {
        active: true,
        name: "management-logs",
      }
    ),
    tfx.resource(
      "Workload VPC Flow Logs",
      'ibm_is_flow_log.flow_logs["workload"]',
      {
        active: true,
        name: "workload-logs",
      }
    ),
    tfx.resource(
      "Management VPC Virtual Endpoint Gateway Object Storage",
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
      "Workload VPC Virtual Endpoint Gateway Object Storage",
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
      "Management VPC Endpoint Gateway for Object Storage Reserved IP  Zone 1",
      'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-1-ip"]',
      {}
    ),
    tfx.resource(
      "Management VPC Endpoint Gateway for Object Storage Reserved IP Zone 2",
      'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-2-ip"]',
      {}
    ),
    tfx.resource(
      "Management VPC Endpoint Gateway for Object Storage Reserved IP Zone 3",
      'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-3-ip"]',
      {}
    ),
    tfx.resource(
      "Workload VPC Endpoint Gateway for Object Storage Reserved IP Zone 1",
      'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-1-ip"]',
      {}
    ),
    tfx.resource(
      "Workload VPC Endpoint Gateway for Object Storage Reserved IP Zone 2",
      'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-2-ip"]',
      {}
    ),
    tfx.resource(
      "Workload VPC Endpoint Gateway for Object Storage Reserved IP Zone 3",
      'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-3-ip"]',
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
      "Management VPC VPN Gateway",
      'ibm_is_vpn_gateway.gateway["management-gateway"]',
      {
        mode: "route",
        name: "at-test-management-gateway",
        tags: tags,
        timeouts: { create: null, delete: "1h" },
      }
    ),
    tfx.resource(
      "Management Resource Groups",
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
      "Workload Resource Groups",
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

        plan: "standard",
        service: "cloud-object-storage",
        tags: tags,
      }
    ),
    tfx.resource(
      "Cloud Object Storage Bind Resource Key",
      'ibm_resource_key.key["cos-bind-key"]',
      {
        role: "Writer",
        tags: tags,
      }
    ),
    tfx.resource(
      "Management Transit Gateway Connection",
      'ibm_tg_connection.connection["management"]',
      {
        name: "at-test-management-hub-connection",
        network_type: "vpc",
        timeouts: { create: "30m", delete: "30m", update: null },
      }
    ),
    tfx.resource(
      "Workload Transit Gateway Connection",
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
      "Landing Zone Key Management ROKS key",
      'ibm_kms_key.key["at-test-roks-key"]',
      {
        force_delete: true,
        key_name: "at-test-roks-key",
        key_ring_id: "at-test-slz-ring",
        standard_key: false,
      }
    ),
    tfx.resource(
      "Landing Zone Key Management Atracker",
      'ibm_kms_key_policies.key_policy["at-test-roks-key"]',
      {}
    ),
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
      "Landing Zone Key Management Atracker",
      'ibm_kms_key_policies.key_policy["at-test-atracker-key"]',
      {}
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
      "Landing Zone Key Management Atracker",
      'ibm_kms_key_policies.key_policy["at-test-vsi-volume-key"]',
      {}
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
      "Landing Zone Key Management Atracker",
      'ibm_kms_key_policies.key_policy["at-test-slz-key"]',
      {}
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
      public_key: "ssh-rsa AAAAthisisatesthihello==",
      tags: tags,
    })
  );
  tfx.module(
    "Management Virtual Private Cloud",
    'module.acceptance_tests.module.landing-zone.module.vpc["management"]',
    tfx.resource(
      "Management Virtual Private Cloud VPN Zone 1",
      'ibm_is_subnet.subnet["at-test-management-vpn-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.10.30.0/24",
        name: "at-test-management-vpn-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud ACL",
      'ibm_is_network_acl.network_acl["management-acl"]',
      {
        name: "at-test-management-acl",
        rules: aclRules.workload,
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet VPE Zone 1",
      'ibm_is_subnet.subnet["at-test-management-vpe-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.10.20.0/24",
        name: "at-test-management-vpe-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet VPE Zone 2",
      'ibm_is_subnet.subnet["at-test-management-vpe-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.20.20.0/24",
        name: "at-test-management-vpe-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet VPE Zone 3",
      'ibm_is_subnet.subnet["at-test-management-vpe-zone-3"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.30.20.0/24",
        name: "at-test-management-vpe-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet Prefix VPN Zone 1",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vpn-zone-1"]',
      {
        cidr: "10.10.30.0/24",
        is_default: false,
        name: "at-test-management-vpn-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet VSI Zone 1",
      'ibm_is_subnet.subnet["at-test-management-vsi-zone-1"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.10.10.0/24",
        name: "at-test-management-vsi-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet VSI Zone 2",
      'ibm_is_subnet.subnet["at-test-management-vsi-zone-2"]',
      {
        ip_version: "ipv4",
        ipv4_cidr_block: "10.20.10.0/24",
        name: "at-test-management-vsi-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet VSI Zone 3",
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
      "Management Virtual Private Cloud Subnet Address Prefix VPE Zone 1",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vpe-zone-1"]',
      {
        cidr: "10.10.20.0/24",
        is_default: false,
        name: "at-test-management-vpe-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet Address Prefix VPE Zone 2",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vpe-zone-2"]',
      {
        cidr: "10.20.20.0/24",
        is_default: false,
        name: "at-test-management-vpe-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet Address Prefix VPE Zone 3",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vpe-zone-3"]',
      {
        cidr: "10.30.20.0/24",
        is_default: false,
        name: "at-test-management-vpe-zone-3",
        zone: "us-south-3",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet Address Prefix VSI Zone 1",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vsi-zone-1"]',
      {
        cidr: "10.10.10.0/24",
        is_default: false,
        name: "at-test-management-vsi-zone-1",
        zone: "us-south-1",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet Address Prefix VSI Zone 2",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vsi-zone-2"]',
      {
        cidr: "10.20.10.0/24",
        is_default: false,
        name: "at-test-management-vsi-zone-2",
        zone: "us-south-2",
      }
    ),
    tfx.resource(
      "Management Virtual Private Cloud Subnet Address Prefix VSI Zone 3",
      'ibm_is_vpc_address_prefix.subnet_prefix["at-test-management-vsi-zone-3"]',
      {
        cidr: "10.30.10.0/24",
        is_default: false,
        name: "at-test-management-vsi-zone-3",
        zone: "us-south-3",
      }
    )
  ),
    tfx.module(
      "Workload Virtual Private Cloud",
      'module.acceptance_tests.module.landing-zone.module.vpc["workload"]',
      tfx.resource(
        "Workload Virtual Private Cloud ACL",
        'ibm_is_network_acl.network_acl["workload-acl"]',
        {
          name: "at-test-workload-acl",
          rules: aclRules.workload,
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet VPE Zone 1",
        'ibm_is_subnet.subnet["at-test-workload-vpe-zone-1"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.40.20.0/24",
          name: "at-test-workload-vpe-zone-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet VPE Zone 2",
        'ibm_is_subnet.subnet["at-test-workload-vpe-zone-2"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.50.20.0/24",
          name: "at-test-workload-vpe-zone-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet VPE Zone 3",
        'ibm_is_subnet.subnet["at-test-workload-vpe-zone-3"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.60.20.0/24",
          name: "at-test-workload-vpe-zone-3",
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet VSI Zone 1",
        'ibm_is_subnet.subnet["at-test-workload-vsi-zone-1"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.40.10.0/24",
          name: "at-test-workload-vsi-zone-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet VSI Zone 2",
        'ibm_is_subnet.subnet["at-test-workload-vsi-zone-2"]',
        {
          ip_version: "ipv4",
          ipv4_cidr_block: "10.50.10.0/24",
          name: "at-test-workload-vsi-zone-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet VSI Zone 3",
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
        "Workload Virtual Private Cloud Subnet Address Prefix VPE Zone 1",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vpe-zone-1"]',
        {
          cidr: "10.40.20.0/24",
          is_default: false,
          name: "at-test-workload-vpe-zone-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet Address Prefix VPE Zone 2",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vpe-zone-2"]',
        {
          cidr: "10.50.20.0/24",
          is_default: false,
          name: "at-test-workload-vpe-zone-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet Address Prefix VPE Zone 3",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vpe-zone-3"]',
        {
          cidr: "10.60.20.0/24",
          is_default: false,
          name: "at-test-workload-vpe-zone-3",
          zone: "us-south-3",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet Address Prefix VSI Zone 1",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vsi-zone-1"]',
        {
          cidr: "10.40.10.0/24",
          is_default: false,
          name: "at-test-workload-vsi-zone-1",
          zone: "us-south-1",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet Address Prefix VSI Zone 2",
        'ibm_is_vpc_address_prefix.subnet_prefix["at-test-workload-vsi-zone-2"]',
        {
          cidr: "10.50.10.0/24",
          is_default: false,
          name: "at-test-workload-vsi-zone-2",
          zone: "us-south-2",
        }
      ),
      tfx.resource(
        "Workload Virtual Private Cloud Subnet Address Prefix VSI Zone 3",
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
        "Management Virtual Server Instance Server 2",
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
        "Management Virtual Server Instance Server 3",
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
        "Management Virtual Server Instance Security Group",
        'ibm_is_security_group.security_group["at-test-management"]',
        {
          name: "at-test-management",
        }
      ),
      tfx.resource(
        "Management Virtual Server Instance Security Group Rules Inbound",
        'ibm_is_security_group_rule.security_group_rules["at-test-management-allow-ibm-inbound"]',
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
        "Management Virtual Server Instance Security Group Rules Inbound",
        'ibm_is_security_group_rule.security_group_rules["at-test-management-allow-vpc-inbound"]',
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
        "Management Virtual Server Instance Security Group Rules Outbound",
        'ibm_is_security_group_rule.security_group_rules["at-test-management-allow-ibm-tcp-443-outbound"]',
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
        "Management Virtual Server Instance Security Group Rules Outbound",
        'ibm_is_security_group_rule.security_group_rules["at-test-management-allow-ibm-tcp-53-outbound"]',
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
        "Management Virtual Server Instance Security Group Rules Outbound",
        'ibm_is_security_group_rule.security_group_rules["at-test-management-allow-ibm-tcp-80-outbound"]',
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
        "Management Virtual Server Instance Security Group Rules Outbound",
        'ibm_is_security_group_rule.security_group_rules["at-test-management-allow-vpc-outbound"]',
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
