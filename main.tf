resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "GameScores"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "UserId"
  range_key      = "GameTitle"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "GameTitle"
    type = "S"
  }

  attribute {
    name = "TopScore"
    type = "N"
  }

  ttl {
    attribute_name = "TimeToExist"
    enabled        = true
  }

  global_secondary_index {
    name               = "GameTitleIndex"
    hash_key           = "GameTitle"
    range_key          = "TopScore"
    write_capacity     = 10
    read_capacity      = 10
    projection_type    = "INCLUDE"
    non_key_attributes = ["UserId"]
  }

  tags = {
    Name        = "dynamodb-table-1"
    Environment = "production"
  }
}

module "dynamodb_table" {
  source = "terraform-aws-modules/dynamodb-table/aws"
  #   version = "5.0.0"

  name         = "my-table"
  hash_key     = "id"
  range_key    = "entityType"
  billing_mode = local.billing

  attributes = [
    {
      name     = "id"
      type     = "S"
      required = "Yes"
    },

    {
      name     = "entityType"
      type     = "S"
      Required = "Yes"
    },

    {
      name     = "customerId"
      type     = "S"
      required = "Yes"
    },

    {
      name     = "assetReportId"
      type     = "S"
      required = "Yes"
    },

    {
      name     = "assetReportPath"
      type     = "S"
      required = "Yes"
    },

    {
      name     = "sourceId"
      type     = "S"
      required = "Yes"
    }
    # {
    #   name     = "isError"
    #   type     = "S"
    #   required = "Yes"
    # }
  ]


  global_secondary_indexes = [
    {
      name            = "customerIdIndex"
      hash_key        = "customerId"
      write_capacity  = 10
      read_capacity   = 10
      projection_type = "ALL"
    },
    {
      name            = "assetReportIdIndex"
      hash_key        = "assetReportId"
      write_capacity  = 10
      read_capacity   = 10
      projection_type = "ALL"
    },
    {
      name            = "entityTypeIndex"
      hash_key        = "entityType"
      write_capacity  = 10
      read_capacity   = 10
      projection_type = "ALL"
    },
    {
      name            = "sourceIdIndex"
      hash_key        = "sourceId"
      write_capacity  = 10
      read_capacity   = 10
      projection_type = "ALL"
    },
    # {
    #   name            = "isErrorIndex"
    #   hash_key        = "isError"
    #   write_capacity  = 10
    #   read_capacity   = 10
    #   projection_type = "ALL"
    # },
    {
      name            = "assetReportPathIndex"
      hash_key        = "assetReportPath"
      write_capacity  = 10
      read_capacity   = 10
      projection_type = "ALL"
    }
  ]

  tags = local.default_tags
}




data "aws_iam_policy_document" "read_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::224761220970:role/aws-service-role/dynamodb.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_DynamoDBTable"] # Replace with your user ARN
    }
    actions = [
      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
    ]
    resources = [module.dynamodb_table.dynamodb_table_arn] #"arn:aws:dynamodb:us-east-1:224761220970:table/my-table"]
  }

}

resource "aws_dynamodb_resource_policy" "stream_policy" {
  resource_arn = module.dynamodb_table.dynamodb_table_arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowLambdaReadStream",
        Effect = "Allow",
        Principal = {
          AWS = ["arn:aws:iam::224761220970:role/aws-service-role/dynamodb.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_DynamoDBTable"] # Replace with your user ARN
        },
        Action = [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator"
        ],
        Resource = ["${module.dynamodb_table.dynamodb_table_arn}/stream/StreamTimestamp"]
      }
    ]
  })
}


resource "aws_dynamodb_resource_policy" "table_read_policy" {
  resource_arn = module.dynamodb_table.dynamodb_table_arn
  policy       = data.aws_iam_policy_document.read_policy.json
}

# resource "aws_dynamodb_resource_policy" "table_stream_policy" {
#   resource_arn = module.dynamodb_table.dynamodb_table_arn
#   policy       = data.aws_dynamodb_resource_policy.stream_policy.json
# }

output "table_arn_from_module" {
  description = "The ARN of the DynamoDB table created by the module."
  value       = module.dynamodb_table.dynamodb_table_arn
}


# output "stream_arn" {
#   value = data.aws_dynamodb_table.my_table.stream_arn
# }

data "aws_dynamodb_table" "my_table" {
  name = "my-table"
}



