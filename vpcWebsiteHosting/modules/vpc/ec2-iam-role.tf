# trust policy for EC2 
data "aws_iam_policy_document" "assume_role"{
    statement{
        actions =["sts:AssumeRole"]
        effect = "Allow"
    }
}

# create IAM role for EC2
resource "aws_iam_role" "ec2_role"{
    name = "ec2-role"
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
    tags = var.tags
}

#attach AWS managed policy to the role (SSM)
resource "aws_iam_role_policy_attachment" "ec2_ssm_policy" {
    role = aws_iam_role.ec2_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

#Least Privilage policy for S3 access
resource "aws_iam_role_policy" "s3_access"{
    name = "${var.ec2_role_name}-s3-access"
    role = aws_iam_role.ec2_role.id

    policy = jsonecode({
        version = "2012-10-17"
        statement = [
            {
                sid = "ListBucket"
                effect = "Allow"
                resource = "[${var.bucket_arn}]"
            },
            {
                sid = "GetObjects"
                effect = "Allow"
                resource = "[${var.bucket_arn}/*]"
            }
        ]
    })
}

# instance profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "${var.ec2_role_name}-instance-profile"
    role = aws_iam_role.ec2_role.name
    tags = var.tags
}