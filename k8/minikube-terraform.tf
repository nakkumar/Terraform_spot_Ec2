##########################################
#            PROVIDER-AWS                #
##########################################

provider "aws" {
  region = "ap-south-2"
}

##########################################
#       MINIKUBE-SERVER-LAUNCH           #
##########################################

resource "aws_instance" "TF-test"{
    ami  = "ami-024ebedf48d280810"
    instance_type = "t3.small"
    subnet_id = "subnet-033bd3dde8b3ed93a"
    key_name = "MT5-DEMO"
    vpc_security_group_ids = ["sg-063db659abab09ea8"]
    user_data_base64 = base64encode(file("userdata.sh"))

    root_block_device {

      volume_size = 30
      volume_type = "gp2"

      delete_on_termination = true
   }

  tags = {
    Name = "MiniKube-k8"
  }
}

output "ec2_public_ip" {
  value = aws_instance.TF-test.public_ip
}
