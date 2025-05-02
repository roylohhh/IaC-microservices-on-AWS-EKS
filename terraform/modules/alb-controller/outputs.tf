output "alb_controller_role_arn" {
  description = "IAM role ARN for ALB Controller"
  value       = aws_iam_role.alb_controller_irsa.arn
}

output "helm_release_status" {
  description = "Helm release status"
  value       = helm_release.alb_controller.status
}
