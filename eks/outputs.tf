output "eks_cluster_endpoint" {
  description = "Eks cluster endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

output "eks_node_role_arn" {
  description = "Eks Node role ARN"
  value       = aws_iam_role.eks_worker_role.arn
}

output "eks_node_role_name" {
  description = "Eks Node role name"
  value       = aws_iam_role.eks_worker_role.name
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}
