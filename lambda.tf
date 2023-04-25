provider "aws" {
  region                   = "ap-south-1"
  shared_credentials_files = ["C:\\Users\\hp\\.aws\\credentials"]
}

resource "random_pet" "my_random" {
  prefix = "bharath"
}

resource "aws_s3_bucket" "my_s3_bucket" {
  bucket = random_pet.my_random.id
}

resource "aws_iam_role" "lambda_role" {
  name = "aws_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_policy"
  path        = "/"
  description = "My test policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:Get*",
          "s3:List*",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "policy_attachment" {
  name       = "policy_attacments"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_policy.arn
}

data "archive_file" "my_archive" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/aws-s3-python.zip"
}

resource "aws_lambda_function" "my_lambda_func" {
  filename      = "${path.module}/python/aws-s3-python.zip"
  function_name = "sample-s3-function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "aws-s3-python.lambda_handler"
  runtime       = "python3.8"
  depends_on    = [aws_iam_policy_attachment.policy_attachment, aws_s3_bucket.my_s3_bucket]
}

output "terraform_aws_iam_role_name" {
  value = aws_iam_role.lambda_role.name
}

output "terraform_aws_iam_role_arn" {
  value = aws_iam_role.lambda_role.arn
}
