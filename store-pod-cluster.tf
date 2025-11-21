locals {
  profiles = join(",", compact(["fargate", var.test_stores ? "test-stores" : ""]))
  default_capacity_provider = {
    FARGATE = {
      weight = 50
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }
  services = {
    "landing-ui" = {
      public                      = true
      priority                    = 100
      service_type                = "SERVICE"
      loadbalancer_target_groups  = {}
      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "landing-ui"
      main_container_port         = 8110
      health_check = {
        path                = "/"
        port                = 8110
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "landing-ui" = {
          image = "${var.docker_registry}/store-pod/landing-ui:${var.image_tag}"
          environment : [
            { "name" : "OTEL_SERVICE_NAME", "value" : "landing-ui" },
            { "name" : "OTEL_EXPORTER_OTLP_PROTOCOL", "value" : "grpc" },
            { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.pod.namespace}:4317" },
            { "name" : "INTERNAL_STORE_POD_GATEWAY", "value" : "http://store-pod-saas-gateway.${var.pod.namespace}:80" }
          ]
          secrets : []
          portMappings : [
            {
              name : "app",
              containerPort : 8110,
              hostPort : 8110,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "merchant" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "merchant"
      main_container_port         = 8120
      health_check = {
        path                = "/actuator/health"
        port                = 8120
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "merchant" = {
          image = "${var.docker_registry}/store-pod/merchant:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : local.profiles },
            { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.pod.namespace}:4318" },
            { "name" : "OTEL_SDK_DISABLED", "value" : !var.is_monitoring },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.namespace },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_PROVIDER", "value" : "S3" },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_BUCKET", "value" : module.cdn-storage-bucket.s3_bucket_id },
            {
              "name" : "COM_ASREVO_CVHOME_CDN_BASE-PATH",
              "value" : "https://${module.cdn-storage-cloudfront.cloudfront_distribution_domain_name}"
            },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MERCHANT_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CONTENT_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CATALOG_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_ORDER_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_POD-INFO_POD_ID_ID", "value" : var.pod.id },
            { "name" : "COM_ASREVO_CVHOME_POD-INFO_POD_NAME", "value" : var.pod.name },
            { "name" : "COM_ASREVO_CVHOME_POD-INFO_POD_ENDPOINT_ENDPOINT", "value" : var.pod.endpoint },
            { "name" : "COM_ASREVO_CVHOME_POD-INFO_POD_ENDPOINT_TYPE", "value" : var.pod.endpointType },
            {
              "name" : "COM_ASREVO_CVHOME_POD-INFO_POD_DOMAIN",
              "value" : "store-pod-saas-gateway-${var.pod.id}.${var.domain_zone_name}"
            },
            { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-pod-db.db_instance_name },
            { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-pod-db.db_instance_address },
            { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-pod-db.db_instance_port },
            { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-pod-db.db_instance_username },
          ]
          secrets : [
            {
              name : "SPRING_DATASOURCE_PASSWORD",
              valueFrom = "${module.store-pod-db.db_instance_master_user_secret_arn}:password::"
            }
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 8120,
              hostPort : 8120,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "content" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "content"
      main_container_port         = 8121
      health_check = {
        path                = "/actuator/health"
        port                = 8121
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "content" = {
          image = "${var.docker_registry}/store-pod/content:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : local.profiles },
            { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.pod.namespace}:4318" },
            { "name" : "OTEL_SDK_DISABLED", "value" : !var.is_monitoring },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.namespace },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_PROVIDER", "value" : "S3" },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_BUCKET", "value" : module.cdn-storage-bucket.s3_bucket_id },
            {
              "name" : "COM_ASREVO_CVHOME_CDN_BASE-PATH",
              "value" : "https://${module.cdn-storage-cloudfront.cloudfront_distribution_domain_name}"
            },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MERCHANT_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CONTENT_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CATALOG_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_ORDER_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-pod-db.db_instance_name },
            { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-pod-db.db_instance_address },
            { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-pod-db.db_instance_port },
            { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-pod-db.db_instance_username },
          ]
          secrets : [
            {
              name : "SPRING_DATASOURCE_PASSWORD",
              valueFrom = "${module.store-pod-db.db_instance_master_user_secret_arn}:password::"
            }
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 8121,
              hostPort : 8121,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "catalog" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "catalog"
      main_container_port         = 8122
      health_check = {
        path                = "/actuator/health"
        port                = 8122
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "catalog" = {
          image = "${var.docker_registry}/store-pod/catalog:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : local.profiles },
            { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.pod.namespace}:4318" },
            { "name" : "OTEL_SDK_DISABLED", "value" : !var.is_monitoring },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.namespace },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_PROVIDER", "value" : "S3" },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_BUCKET", "value" : module.cdn-storage-bucket.s3_bucket_id },
            {
              "name" : "COM_ASREVO_CVHOME_CDN_BASE-PATH",
              "value" : "https://${module.cdn-storage-cloudfront.cloudfront_distribution_domain_name}"
            },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MERCHANT_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CONTENT_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CATALOG_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_ORDER_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-pod-db.db_instance_name },
            { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-pod-db.db_instance_address },
            { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-pod-db.db_instance_port },
            { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-pod-db.db_instance_username },
          ]
          secrets : [
            {
              name : "SPRING_DATASOURCE_PASSWORD",
              valueFrom = "${module.store-pod-db.db_instance_master_user_secret_arn}:password::"
            }
          ]
          portMappings : [
            {
              name : "app",
              containerPort : 8122,
              hostPort : 8122,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "order" = {
      public                     = true
      priority                   = 100
      service_type               = "SERVICE"
      loadbalancer_target_groups = {}

      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "order"
      main_container_port         = 8123
      health_check = {
        path                = "/actuator/health"
        port                = 8123
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "order" = {
          image = "${var.docker_registry}/store-pod/order:${var.image_tag}"
          environment : [
            { "name" : "SPRING_PROFILES_ACTIVE", "value" : local.profiles },
            { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.pod.namespace}:4318" },
            { "name" : "OTEL_SDK_DISABLED", "value" : !var.is_monitoring },
            { "name" : "COM_ASREVO_CVHOME_APP_DOMAIN", "value" : var.domain },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_STORE-CORE-GATEWAY_PORT", "value" : "443" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_SCHEMA", "value" : "https" },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CORE-AUTH_PORT", "value" : "443" },
            { "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE", "value" : var.pod.namespace },
            {
              "name" : "SPRING_CLOUD_ECS_DISCOVERY_NAMESPACE-ID",
              "value" : aws_service_discovery_private_dns_namespace.cluster_namespace.id
            },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_PROVIDER", "value" : "S3" },
            { "name" : "COM_ASREVO_CVHOME_CDN_STORAGE_BUCKET", "value" : module.cdn-storage-bucket.s3_bucket_id },
            {
              "name" : "COM_ASREVO_CVHOME_CDN_BASE-PATH",
              "value" : "https://${module.cdn-storage-cloudfront.cloudfront_distribution_domain_name}"
            },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_MERCHANT_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CONTENT_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_CATALOG_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "COM_ASREVO_CVHOME_SERVICES_ORDER_NAMESPACE", "value" : var.pod.namespace },
            { "name" : "SPRING_DATASOURCE_DATABASE", "value" : module.store-pod-db.db_instance_name },
            { "name" : "SPRING_DATASOURCE_HOST", "value" : module.store-pod-db.db_instance_address },
            { "name" : "SPRING_DATASOURCE_PORT", "value" : module.store-pod-db.db_instance_port },
            { "name" : "SPRING_DATASOURCE_USERNAME", "value" : module.store-pod-db.db_instance_username },
          ]
          secrets : [
            {
              name : "SPRING_DATASOURCE_PASSWORD",
              valueFrom = "${module.store-pod-db.db_instance_master_user_secret_arn}:password::"
            }
          ]

          portMappings : [
            {
              name : "app",
              containerPort : 8123,
              hostPort : 8123,
              protocol : "tcp"
            }
          ]
        }
      }
    }
    "store-pod-saas-gateway" = {
      public       = true
      priority     = 100
      service_type = "SERVICE"
      loadbalancer_target_groups = {
        "gateway-tg-80" : {
          loadbalancer_target_groups_arn = module.cluster-nlb.target_groups["gateway-tg-80"].arn
          main_container                 = "store-pod-saas-gateway"
          main_container_port            = 80
        }
        "gateway-tg-443" : {
          loadbalancer_target_groups_arn = module.cluster-nlb.target_groups["gateway-tg-443"].arn
          main_container                 = "store-pod-saas-gateway"
          main_container_port            = 443
        }
      }



      load_balancer_host_matchers = []
      desired                     = 1
      cpu                         = 512
      memory                      = 1024
      main_container              = "store-pod-saas-gateway"
      main_container_port         = 443
      health_check = {
        path                = "/"
        port                = 80
        healthy_threshold   = 2
        interval            = 60
        unhealthy_threshold = 3
      }

      containers = {
        "store-pod-saas-gateway" = {
          image = "${var.docker_registry}/store-pod/store-pod-saas-gateway:${var.image_tag}"
          environment : [
            { "name" : "NAMESPACE", "value" : var.pod.namespace },
            {
              "name" : "ASK_TLS_URL",
              "value" : "http://merchant.${var.pod.namespace}:8120/api/v1/router/public/ask-for-tls"
            },
            {
              "name" : "DOMAIN_LOOKUP_URL",
              "value" : "http://merchant.${var.pod.namespace}:8120/api/v1/router/public/lookup-by-domain"
            },
            {
              "name" : "CERT_BUCKET",
              "value" : module.cert-storage-bucket.s3_bucket_id
            },
            {
              "name" : "CERT_BUCKET_REGION",
              "value" : module.cert-storage-bucket.s3_bucket_region
            },
            {
              "name" : "ACME_CA_URL",
              "value" : "https://acme-v02.api.letsencrypt.org/directory"
            },
            { "name" : "OTEL_SERVICE_NAME", "value" : "store-pod-saas-gateway" },
            { "name" : "OTEL_EXPORTER_OTLP_PROTOCOL", "value" : "grpc" },
            { "name" : "OTEL_EXPORTER_OTLP_ENDPOINT", "value" : "http://otel-collector.${var.pod.namespace}:4317" },
            {
              "name" : "DOMAIN_LOOKUP_TTL",
              "value" : var.is_prod ? "5m" : "1m"
            }
          ]
          secrets : []
          portMappings : [
            {
              name : "app443",
              containerPort : 443,
              hostPort : 443,
              protocol : "tcp"
            },
            {
              name : "app80",
              containerPort : 80,
              hostPort : 80,
              protocol : "tcp"
            },
            {
              name : "app2019",
              containerPort : 2019,
              hostPort : 2019,
              protocol : "tcp"
            }
          ]
        }
      }
    }

  }
}

module "store-pod-cluster" {
  source                             = "terraform-aws-modules/ecs/aws"
  cluster_name                       = "${local.module_name}-${var.project}-${var.env}"
  default_capacity_provider_strategy = local.default_capacity_provider
  tags                               = var.tags
}

module "store-pod-service" {
  source       = "git::https://github.com/cvhome-saas/cvhome-common-ecs-service.git?ref=main"
  namespace_id = aws_service_discovery_private_dns_namespace.cluster_namespace.id
  service_name = each.key
  tags         = var.tags
  cluster_name = module.store-pod-cluster.cluster_name
  env          = var.env
  module_name  = local.module_name
  project      = var.project
  service      = each.value
  subnet       = var.public_subnets
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow ingress traffic access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow egress traffic access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  auto_scale = var.pod_auto_scale
  for_each   = local.services
  vpc_id     = var.vpc_id
}

module "monitoring-collector-service" {
  source       = "git::https://github.com/cvhome-saas/cvhome-common-ecs-service.git?ref=main"
  namespace_id = aws_service_discovery_private_dns_namespace.cluster_namespace.id
  service_name = "otel-collector"
  tags         = var.tags
  cluster_name = module.store-pod-cluster.cluster_name
  env          = var.env
  module_name  = local.module_name
  project      = var.project
  service = {
    public                      = true
    priority                    = 100
    service_type                = "SERVICE"
    loadbalancer_target_groups  = {}
    load_balancer_host_matchers = []
    desired                     = 1
    cpu                         = 512
    memory                      = 1024
    main_container              = "otel-collector"
    main_container_port         = 4318
    health_check = {
      path                = "/"
      port                = 4318
      healthy_threshold   = 2
      interval            = 60
      unhealthy_threshold = 3
    }

    containers = {
      "otel-collector" = {
        image = "ashraf1abdelrasool/aws-otel-collector:latest"
        environment : [
          { "name" : "AWS_REGION", "value" : var.region }
        ]
        secrets : []
        portMappings : [
          {
            name : "app4317",
            containerPort : 4317,
            hostPort : 4317,
            protocol : "tcp"
          },
          {
            name : "app4318",
            containerPort : 4318,
            hostPort : 4318,
            protocol : "tcp"
          }
        ]
      }
    }
  }
  subnet = var.public_subnets
  ingress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow ingress traffic access from within VPC"
      cidr_blocks = var.vpc_cidr_block
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow egress traffic access"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  auto_scale = var.pod_auto_scale
  vpc_id     = var.vpc_id
  count      = var.is_monitoring ? 1 : 0
}