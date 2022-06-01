##############################################################################
# [Unit Test] Get Subnets
##############################################################################

module "ut_get_subnets" {
  source = "./config_modules/get_subnets"
  subnet_zone_list = [
    {
      name = "ut-vpc-bad-subnet"
    },
    {
      name = "ut-vpc-good-subnet"
    }
  ]
  regex = "ut-vpc-good-subnet"
}

locals {
  assert_get_subnets_correct_name = regex("ut-vpc-good-subnet", module.ut_get_subnets.subnets[0].name)
}

##############################################################################