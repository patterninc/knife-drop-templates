
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["{VPC_NAME}"]
  }
}

data "aws_subnets" "private" {
  filter {
    name = "vpc-id"
    values = [
      data.aws_vpc.vpc.id,
    ]
  }
  filter {
    name = "tag:Name"
    values = [
      "*-private-*",
    ]
  }
}

data "aws_subnets" "public" {
  filter {
    name = "vpc-id"
    values = [
      data.aws_vpc.vpc.id,
    ]
  }
  filter {
    name = "tag:Name"
    values = [
      "*-public-*",
    ]
  }
}
