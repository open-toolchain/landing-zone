const jsutil = require("util"); // Utils to run child process
const exec = jsutil.promisify(require("child_process").exec); // Exec from child process
const { assert, util } = require("chai");
const tags = ["landing-zone", "unit-test"];
const tfUnitTestUtils = require("./utils/utils.js");
const tfutils = new tfUnitTestUtils("./plan_test.sh", "../defaults");
let plannedValues; // Initialized planned values

describe("Landing Zone Plan",  () => {
  before( async() => {
    await tfutils.getPlanJson(exec).then((tfplan) => {
      plannedValues = tfplan;
    });
  });
  // It statement is nessecary to force the async/await before
  it("should wait for the data to be retrieved", () => {
    describe("Root Module", () => {
      tfutils.testModule("Root Module", "module.landing_zone", plannedValues, [
        {
          name: "Activity Tracker Route",
          address: "ibm_atracker_route.atracker_route",
          values: {
            name: "ut-atracker-route",
            receive_global_events: true,
          },
        },
        {
          name: "Activity Tracker Target",
          address: "ibm_atracker_target.atracker_target",
          values: {
            cos_endpoint: [
              {
                bucket: "ut-atracker-bucket",
                endpoint:
                  "s3.private.us-south.cloud-object-storage.appdomain.cloud",
              },
            ],
            target_type: "cloud_object_storage",
            name: "ut-atracker",
          },
        },
        {
          name: "Workload Cluster",
          address: `ibm_container_vpc_cluster.cluster[\"ut-workload-cluster\"]`,
          values: {
            disable_public_service_endpoint: true,
            entitlement: "cloud_pak",
            flavor: "bx2.16x64",
            kube_version: function (value) {
              return {
                appendMessage: "to contain _openshift. Got " + value,
                expectedData: value.indexOf("_openshift") !== -1,
              };
            },
            name: "ut-workload-cluster",
            tags: tags,
            timeouts: { create: "3h", delete: "2h", update: null },
            wait_till: "IngressReady",
            worker_count: 2,
            zones: [
              { name: "us-south-1" },
              { name: "us-south-2" },
              { name: "us-south-3" },
            ],
          },
        },
        {
          name: "Workload Cluster Logging Pool",
          address: `ibm_container_vpc_worker_pool.pool[\"ut-workload-cluster-logging-worker-pool\"]`,
          values: {
            entitlement: "cloud_pak",
            flavor: "bx2.16x64",
            worker_count: 2,
            worker_pool_name: "logging-worker-pool",
            zones: [
              { name: "us-south-1" },
              { name: "us-south-2" },
              { name: "us-south-3" },
            ],
          },
        },
        {
          name: "Activity Tracker Object Storage Bucket",
          address: `ibm_cos_bucket.buckets[\"atracker-bucket\"]`,
          values: {
            bucket_name: "ut-atracker-bucket",
            cross_region_location: null,
            endpoint_type: "public",
            force_delete: true,
            hard_quota: null,
            region_location: "us-south",
            retention_rule: [],
            single_site_location: null,
            storage_class: "standard",
          },
        },
        {
          name: "Management Object Storage Bucket",
          address: `ibm_cos_bucket.buckets[\"management-bucket\"]`,
          values: {
            bucket_name: "ut-management-bucket",
            cross_region_location: null,
            endpoint_type: "public",
            force_delete: true,
            hard_quota: null,
            region_location: "us-south",
            retention_rule: [],
            single_site_location: null,
            storage_class: "standard",
          },
        },
        {
          name: "Management Object Storage Bucket",
          address: `ibm_cos_bucket.buckets[\"workload-bucket\"]`,
          values: {
            bucket_name: "ut-workload-bucket",
            cross_region_location: null,
            endpoint_type: "public",
            force_delete: true,
            hard_quota: null,
            region_location: "us-south",
            retention_rule: [],
            single_site_location: null,
            storage_class: "standard",
          },
        },
        {
          name: "IAM Policy Flow Logs to Atracker Object Storage",
          address: `ibm_iam_authorization_policy.policy[\"atracker-cos-flow-logs-cos\"]`,
          values: {
            description:
              "Allow flow logs write access cloud object storage instance",
            roles: ["Writer"],
            source_resource_type: "flow-log-collector",
            source_service_name: "is",
            target_resource_group_id: null,
            target_resource_type: null,
            target_service_name: "cloud-object-storage",
          },
        },
        {
          name: "IAM Policy Atracker Object Storage to Key Managemnet",
          address: `ibm_iam_authorization_policy.policy[\"cos-atracker-cos-to-kms\"]`,
          values: {
            description: "Allow COS instance to read from KMS instance",
            roles: ["Reader"],
            source_resource_group_id: null,
            source_resource_type: null,
            source_service_name: "cloud-object-storage",
            target_resource_group_id: null,
            target_resource_type: null,
            target_service_name: "kms",
          },
        },
        {
          name: "IAM Policy Atracker Object Storage to Key Managemnet",
          address: `ibm_iam_authorization_policy.policy[\"cos-cos-to-kms\"]`,
          values: {
            description: "Allow COS instance to read from KMS instance",
            roles: ["Reader"],
            source_resource_group_id: null,
            source_resource_type: null,
            source_service_name: "cloud-object-storage",
            target_resource_group_id: null,
            target_resource_type: null,
            target_service_name: "kms",
          },
        },
        {
          name: "IAM Policy Flow Logs to Object Storage",
          address: `ibm_iam_authorization_policy.policy[\"cos-flow-logs-cos\"]`,
          values: {
            description:
              "Allow flow logs write access cloud object storage instance",
            roles: ["Writer"],
            source_resource_type: "flow-log-collector",
            source_service_name: "is",
            target_resource_group_id: null,
            target_resource_type: null,
            target_service_name: "cloud-object-storage",
          },
        },
        {
          name: "IAM Policy Management Resource Group to Block Storage",
          address:
            'ibm_iam_authorization_policy.policy["slz-management-rg-block-storage"]',
          values: {
            description:
              "Allow block storage volumes to be encrypted by KMS instance",
            roles: ["Reader"],
            source_resource_instance_id: null,
            source_resource_type: null,
            source_service_name: "server-protect",
            target_resource_group_id: null,
            target_resource_type: null,
            target_service_name: "kms",
          },
        },
        {
          name: "IAM Policy Workload Resource Group to Block Storage",
          address:
            'ibm_iam_authorization_policy.policy["slz-workload-rg-block-storage"]',
          values: {
            description:
              "Allow block storage volumes to be encrypted by KMS instance",
            roles: ["Reader"],
            source_resource_instance_id: null,
            source_resource_type: null,
            source_service_name: "server-protect",
            target_resource_group_id: null,
            target_resource_type: null,
            target_service_name: "kms",
          },
        },
        {
          name: "Flow Logs for Management VPC",
          address: 'ibm_is_flow_log.flow_logs["management"]',
          values: {
            active: true,
            name: "management-logs",
            storage_bucket: "ut-management-bucket",
            timeouts: null,
          },
        },
        {
          name: "Flow Logs for Workload VPC",
          address: 'ibm_is_flow_log.flow_logs["workload"]',
          values: {
            active: true,
            name: "workload-logs",
            storage_bucket: "ut-workload-bucket",
            timeouts: null,
          },
        },
        {
          name: "Virtual Endpoint Gateway Object Storage for Management VPC",
          address:
            'ibm_is_virtual_endpoint_gateway.endpoint_gateway["management-cos"]',
          values: {
            name: "ut-management-cos",
            target: [
              {
                crn: "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.us-south.cloud-object-storage.appdomain.cloud",
                name: null,
                resource_type: "provider_cloud_service",
              },
            ],
          },
        },
        {
          name: "Virtual Endpoint Gateway Object Storage for Workload VPC",
          address:
            'ibm_is_virtual_endpoint_gateway.endpoint_gateway["workload-cos"]',
          values: {
            name: "ut-workload-cos",
            target: [
              {
                crn: "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.us-south.cloud-object-storage.appdomain.cloud",
                name: null,
                resource_type: "provider_cloud_service",
              },
            ],
          },
        },
        {
          name: "Endpoint Gateway for Object Storage Reserved IP Management VPC Zone 1",
          address:
            'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-1-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway for Object Storage Reserved IP Management VPC Zone 2",
          address:
            'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-2-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway for Object Storage Reserved IP Management VPC Zone 3",
          address:
            'ibm_is_subnet_reserved_ip.ip["management-cos-gateway-vpe-zone-2-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway for Object Storage Reserved IP Workload VPC Zone 1",
          address:
            'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-1-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway for Object Storage Reserved IP Workload VPC Zone 2",
          address:
            'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-2-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway for Object Storage Reserved IP Workload VPC Zone 3",
          address:
            'ibm_is_subnet_reserved_ip.ip["workload-cos-gateway-vpe-zone-2-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway IP For Management COS Zone 1",
          address:
            'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["management-cos-gateway-vpe-zone-1-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway IP For Management COS Zone 2",
          address:
            'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["management-cos-gateway-vpe-zone-2-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway IP For Management COS Zone 3",
          address:
            'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["management-cos-gateway-vpe-zone-3-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway IP For Workload COS Zone 1",
          address:
            'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["workload-cos-gateway-vpe-zone-1-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway IP For Workload COS Zone 2",
          address:
            'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["workload-cos-gateway-vpe-zone-2-ip"]',
          values: {},
        },
        {
          name: "Endpoint Gateway IP For Workload COS Zone 3",
          address:
            'ibm_is_virtual_endpoint_gateway_ip.endpoint_gateway_ip["workload-cos-gateway-vpe-zone-3-ip"]',
          values: {},
        },
        {
          name: "VPN Gateway for Management VPC",
          address: 'ibm_is_vpn_gateway.gateway["management-gateway"]',
          values: {
            mode: "route",
            name: "ut-management-gateway",
            tags: tags,
            timeouts: { create: null, delete: "1h" },
          },
        },
      ]);
      tfutils.testModule("SSH Key Module", "module.ssh_keys", plannedValues, [
        {
          name: "Landing Zone SSH Key",
          address: `ibm_is_ssh_key.ssh_key[\"slz-ssh-key\"]`,
          data: {
            type: "ibm_is_ssh_key",
            name: "ssh_key",
          },
          values: {
            name: "ut-slz-ssh-key",
            public_key: "<user-determined-value>",
            tags: tags,
          },
        },
      ]);
    });
  });
});
