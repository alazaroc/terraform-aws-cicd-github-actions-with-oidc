# Terraform + GitHub Actions (OIDC) - Automatic AWS deployment

> Based on my article: **Automating AWS Resource Deployment with GitHub Actions and Terraform**: https://www.playingaws.com/posts/automating-aws-resource-deployment-with-github-actions-and-terraform/

This repository demonstrates deploying **Terraform** to **AWS** via **GitHub Actions** using **OIDC** (no long‑lived secrets). It provisions a tiny **AWS Budget** (USD 0.1/mo) as a canary to validate the CI/CD flow.

## Whats inside

- `main.tf`: AWS provider, optional S3 **remote backend**, and an `aws_budgets_budget` resource.
- `.github/workflows/terraform-deploy.yml`: split **plan/apply**, supports **Environment approvals**, and authenticates with **OIDC**.

> ⚠️ Using a remote backend (S3) may incur small charges. See **Costs** and **Cleanup**.

If you want to check `how to deploy AWS resources with Terraform and Secrets`, check this other repository: https://github.com/alazaroc/terraform-aws-cicd-github-actions-with-secrets

---

## Requirements

- **AWS account** with permissions for S3 (state and lock), and **AWS Budgets**.
- **GitHub repository** with Actions enabled.
- **Terraform** (≥ 1.5 recommended) if you want to test locally.

### OIDC authentication (recommended)

This repo uses **GitHub OIDC** to obtain **short‑lived credentials** at runtime - no static secrets.

1) Ensure your AWS account has the GitHub **OIDC provider**:  
   - Issuer: `https://token.actions.githubusercontent.com`  
   - Audience: `sts.amazonaws.com`
2) Create an **IAM Role** with this trust policy (restrict it to your repo/branch):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::<YOUR_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<YOUR_ORG_OR_USER>/<YOUR_REPO>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

3) Attach a **least‑privilege policy** for the state bucket/table and Budgets.
4) In the workflow, set:

```yaml
permissions:
  id-token: write
  contents: read

- name: Configure AWS credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::<YOUR_ACCOUNT_ID>:role/<ROLE_FOR_GITHUB>
    aws-region: eu-west-1
```

---

## Using variables (`.tfvars`)

Your `variables.tf` includes safe defaults (e.g., `notification_email = "your_email@domain.com"`), so Terraform works **without** a `.tfvars` file.  
However, its **best practice** to keep real values in a `.tfvars`.

**Recommended (auto‑loaded):**

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
terraform apply -auto-approve
```

**Custom file name:**

```bash
cp terraform.tfvars.example dev.tfvars
# edit dev.tfvars
terraform init
terraform plan -var-file=dev.tfvars
terraform apply -auto-approve -var-file=dev.tfvars
```

> Tip: add `terraform.tfvars`, `*.auto.tfvars`, and any real `*.tfvars` to `.gitignore`.

---

## Local test (optional)

```bash
# Auth for local tests (pick one)
# 1) Not using SSO/role locally:
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_REGION=eu-west-1

# 2) Or using AWS SSO/CLI profile:
export AWS_PROFILE=my-sso-profile

# Initialize and apply with variables (auto-loaded tfvars)
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform init
terraform plan
terraform apply -auto-approve

# Destroy when done
# terraform destroy -auto-approve
```

---

## Troubleshooting

- **Denied on S3** → check least‑privilege policy and resource ARNs.  
- **`AssumeRoleWithWebIdentity` fails** → verify trust policy (`aud` and `sub` values).  
- **Want manual approvals** → keep `environment: production` and configure **Environment protection rules**.  
- **Verify identity** → add a step `aws sts get-caller-identity` in the job.

---

## Costs

- **Budgets**: free.  
- **S3** (state and lock): minimal usage‑based cost.

---

## Cleanup

1) `terraform destroy -auto-approve`  
2) Delete S3 bucket (including versions) if you dont need it anymore.

---

## References

- Full guide: https://www.playingaws.com/posts/automating-aws-resource-deployment-with-github-actions-and-terraform/

---

## Author

Created by **Alejandro Lázaro**. More on my blog: **https://www.playingaws.com**.
