resource "aws_sns_topic" "alert" {
    name = "joshvvcv_alerts"
}

resource "aws_sns_topic_subscription" "alerts_email_josh" {
    topic_arn = aws_sns_topic.alert.arn
    protocol = "email"
    endpoint = "astraljv@gmail.com"
}

# Alarm for monthly budget projection
resource "aws_cloudwatch_metric_alarm" "monthly_cost_projection_20" {
    alarm_name = "MonthlyCostProjection"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 1 # checks once during the below mentioned period
    metric_name = "EstimatedCharges"
    namespace = "AWS/Billing"
    period = 43200 # checks once every 12 hours
    statistic = "Maximum"
    threshold = 20
    alarm_description = "Triggered when monthly AWS costs projection exceeds USD 20"
    alarm_actions = [ aws_sns_topic.alert.arn ]
}

# Alarm for lambda function invocation errors

resource "aws_cloudwatch_metric_alarm" "lambda_invocation_error" {
    alarm_name = "LambdaInvocationError"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = 1
    metric_name = "Errors"
    namespace = "AWS/Lambda"
    period = 3600 # Checks every one hour
    statistic = "Sum"
    threshold = 1   # Trigger if there is at least 1 error
    alarm_description = "Alarm for lambda function invocation error"
    dimensions = {
        FunctionName = module.lambda_visitor_counter.function
    }

    alarm_actions = [ aws_sns_topic.alert.arn ]
  
}

