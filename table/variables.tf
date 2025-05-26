variable "table_name" {
description = "The name of the DynamoDB table"
  type        = string
}

variable "partition_key_name" {
  description = "The name of the partition key (e.g., 'visitor_id' or 'path')"
  type        = string
  default     = "path"
}

variable "partition_key_type" {
  description = "The data type for the partition key (S = string, N = number)"
  type        = string
  default     = "S"
}

variable "tags" {
  description = "A map of tags to assign to the table"
  type        = map(string)
  default     = {}
}

