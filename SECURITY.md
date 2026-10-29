# Security

## Reporting a vulnerability

Please do not open a public issue containing credentials, account identifiers,
or exploitable configuration details. Contact the repository owner privately
through the GitHub profile instead.

## Safe use

- Never commit `terraform.tfstate`, `terraform.tfvars`, access keys, or tokens.
- Use temporary AWS credentials or an approved identity provider.
- Review `terraform plan` before applying or destroying resources.
- Keep `force_destroy = false` for persistent environments.
- Treat the included IAM policy as a project-scoped starting point and review
  it against your organization's security requirements.
