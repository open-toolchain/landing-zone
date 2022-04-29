##############################################################################
# Create Template Data to be used by Teleport VSI
##############################################################################

locals {
  user_data = templatefile(
    "${path.module}/cloud-init.tpl",
    {
      TELEPORT_LICENSE          = var.TELEPORT_LICENSE,
      HTTPS_CERT                = var.HTTPS_CERT,
      HTTPS_KEY                 = var.HTTPS_KEY,
      HOSTNAME                  = var.HOSTNAME
      DOMAIN                    = var.DOMAIN,
      COS_BUCKET                = var.COS_BUCKET,
      COS_BUCKET_ENDPOINT       = var.COS_BUCKET_ENDPOINT
      HMAC_ACCESS_KEY_ID        = var.HMAC_ACCESS_KEY_ID,
      HMAC_SECRET_ACCESS_KEY_ID = var.HMAC_SECRET_ACCESS_KEY_ID,
      APPID_CLIENT_ID           = var.APPID_CLIENT_ID,
      APPID_CLIENT_SECRET       = var.APPID_CLIENT_SECRET,
      APPID_ISSUER_URL          = var.APPID_ISSUER_URL,
      TELEPORT_VERSION          = var.TELEPORT_VERSION,
      CLAIM_TO_ROLES            = var.CLAIM_TO_ROLES,
      MESSAGE_OF_THE_DAY        = var.MESSAGE_OF_THE_DAY
    }
  )
}

data "template_cloudinit_config" "cloud_init" {
  base64_encode = false
  gzip          = false
  part {
    content = local.user_data
  }
}

##############################################################################