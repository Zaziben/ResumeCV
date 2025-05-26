resource "aws_dynamodb_table" "visitor_counter" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"

  hash_key       = var.partition_key_name

  attribute {
    name = var.partition_key_name
    type = var.partition_key_type
  }

  tags = var.tags
}

