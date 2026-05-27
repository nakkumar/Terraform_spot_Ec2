##########################################
#            PROVIDER-AWS                #
##########################################

provider "aws" {
  region = "us-east-1"
}

##########################################
#            VPC-CREATION                #
##########################################

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "Spot-vpc"
  }
}

##########################################
#   PUBLICK & PRIVATE SUBNET CREATION    # 
##########################################

resource "aws_subnet" "main" {
  for_each = {
    pub-subnet1 = {
      cidr = var.pub_sub_cidr1
      az   = "us-east-1a"
    }

    pub-subnet2 = {
      cidr = var.pub_sub_cidr2
      az   = "us-east-1b"
    }

    pri-subnet1 = {
      cidr = var.pri_sub_cidr1
      az   = "us-east-1a"
    }

    pri-subnet2 = {
      cidr = var.pri_sub_cidr2
      az   = "us-east-1b"
    }
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  map_public_ip_on_launch = startswith(each.key, "pub")

  tags = {
    Name = each.key
  }
}

##########################################
#            IGW-CREATION                #
##########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "my-igw"
  }
}
##########################################
#            EIP-CREATION                #
##########################################

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "nat-eip"
  }
} 

##########################################
#         ATTACH-EIP-TO-NAT              #
##########################################
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.main["pub-subnet1"].id

  tags = {
    Name = "my-ngw"
  }
  depends_on = [aws_internet_gateway.igw]
}

##########################################
#             CREATE-RT                  #
##########################################

resource "aws_route_table" "rt" {
  for_each = {
    "public-rt"  = "public"
    "private-rt" = "private"
  }

  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"

    gateway_id     = each.value == "public" ? aws_internet_gateway.igw.id : null
    nat_gateway_id = each.value == "private" ? aws_nat_gateway.nat.id : null
  }

  tags = {
    Name = each.key
  }
}


##########################################
#            RT-ASSOCIATION              #
##########################################

resource "aws_route_table_association" "route_table_assoc" {

  for_each = {
    "public_assoc1" = {
      subnet = aws_subnet.main["pub-subnet1"].id
      route_table = aws_route_table.rt["public-rt"].id
    }
    "private_assoc1" = {
      subnet = aws_subnet.main["pri-subnet1"].id
      route_table = aws_route_table.rt["private-rt"].id
    }

    "public_assoc2" = {
      subnet = aws_subnet.main["pub-subnet2"].id
      route_table = aws_route_table.rt["public-rt"].id
    }
    "private_assoc2" = {
      subnet = aws_subnet.main["pri-subnet2"].id
      route_table = aws_route_table.rt["private-rt"].id
    }    
  }
  subnet_id      = each.value.subnet
  route_table_id = each.value.route_table
}


##########################################
#            SECURITY-GROUP              #
##########################################

resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Spot-web-sg"
  }
}

##########################################
#            AWS-LAUNCH-TMP              #
##########################################

resource "aws_launch_template" "lt" {
    name          = "Spot-LT"
    image_id     = "ami-091138d0f0d41ff90"
    instance_type = "t3.micro"
    key_name      = "devops-TF" 
    vpc_security_group_ids = [aws_security_group.web_sg.id]   
    user_data = base64encode(<<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              apt-get update -y
              apt-get install -y apache2
              systemctl enable apache2
              systemctl start apache2
              echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
              systemctl restart apache2
              EOF
    ) 
}   

##########################################
#         IAM-ROLE-CREATION              #
##########################################


resource "aws_iam_role" "spot_fleet_role" {
  name = "spot-fleet-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "spotfleet.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

##########################################
#       ATTACH-IAM-ROLE-TO-POLICY        #
##########################################
resource "aws_iam_role_policy_attachment" "spot_fleet_attach" {
  role       = aws_iam_role.spot_fleet_role.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole"
}

##########################################
#         SPOT-EC2-REQUEST               #
##########################################

resource "aws_spot_fleet_request" "foo" {
  iam_fleet_role  = aws_iam_role.spot_fleet_role.arn
  spot_price      = "0.1"
  target_capacity = 2
  on_demand_target_capacity = 1
  allocation_strategy = "priceCapacityOptimized"
  on_demand_allocation_strategy = "prioritized"
#  valid_until     = "2019-11-04T20:44:20Z"

 target_group_arns = [
    aws_lb_target_group.tg.arn
  ]

  launch_template_config {
    launch_template_specification {
      id      = aws_launch_template.lt.id
      version = aws_launch_template.lt.latest_version
    }
    overrides {
      subnet_id = aws_subnet.main["pri-subnet1"].id
    }
    overrides {
      subnet_id = aws_subnet.main["pri-subnet2"].id
    }        
  }
    tags = {
      Name = "spot-instance"
    }
  depends_on = [
    aws_iam_role_policy_attachment.spot_fleet_attach,
    aws_nat_gateway.nat,
    aws_route_table.rt    
    ]
}

resource "aws_lb" "alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.web_sg.id
  ]

  subnets = [
    aws_subnet.main["pub-subnet1"].id,
    aws_subnet.main["pub-subnet2"].id
  ]

  tags = {
    Name = "Spot-alb"
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"

  vpc_id = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"

    healthy_threshold   = 2
    unhealthy_threshold = 2

    interval = 30
    timeout  = 5
  }

  tags = {
    Name = "spot-tg"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn

  port     = 80
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}