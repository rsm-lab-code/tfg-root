#provider "aws" {
# region = "us-east-2"
#}

provider "aws" {
 alias = "delegated_account_us-east-2"
 region = "us-east-2"

  assume_role {
    role_arn = "arn:aws:iam::${var.delegated_account_id}:role/OrganizationAccountAccessRole"
  }
}
resource "aws_vpc" "example" {
  cidr_block = "100.0.0.0/16"
  provider    = aws.delegated_account_us-east-2
}

resource "aws_subnet" "firewall_subnet" {
  vpc_id            = aws_vpc.example.id
  provider    = aws.delegated_account_us-east-2
  cidr_block        = "100.0.1.0/24"
  availability_zone = "us-east-2a"
}

resource "aws_networkfirewall_firewall_policy" "example_policy" {
  name = "example-firewall-policy"

  provider    = aws.delegated_account_us-east-2
  stateless_rule_group_reference {
    priority     = 1
    resource_arn = aws_networkfirewall_rule_group.example_stateless.arn
  }

  stateful_rule_group_reference {
    resource_arn = aws_networkfirewall_rule_group.example_stateful.arn
  }
}

resource "aws_networkfirewall_firewall" "example_firewall" {
  name               = "example-firewall"
  provider    = aws.delegated_account_us-east-2
  firewall_policy_arn = aws_networkfirewall_firewall_policy.example_policy.arn
  vpc_id             = aws_vpc.example.id

  subnet_mapping {
    subnet_id = aws_subnet.firewall_subnet.id
  }
}

resource "aws_networkfirewall_rule_group" "example_stateless" {
  capacity = 100
  name     = "example-stateless-rule-group"
  provider    = aws.delegated_account_us-east-2
  type     = "STATELESS"

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              source {
                address_definition = "0.0.0.0/0"
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              protocols = [6]  # TCP
            }
          }
        }
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "example_stateful" {
  capacity = 100
  provider    = aws.delegated_account_us-east-2
  name     = "example-stateful-rule-group"
  type     = "STATEFUL"

  rule_group {
    rules_source {
      rules_string = <<EOT
        pass tcp any any -> any any (msg:"Allow all TCP"; sid:1;)
      EOT
    }
  }
}

