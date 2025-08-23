template-terraform-pipeline-infra
Este repositório contém um template genérico de GitHub Actions para automatizar a implantação e gerenciamento de recursos AWS usando Terraform. Ele foi projetado para ser reutilizável e flexível, permitindo que você gerencie a infraestrutura de múltiplos serviços ou módulos Terraform a partir de um único fluxo de trabalho centralizado.

🚀 Visão Geral e Benefícios
O objetivo principal deste template é padronizar e simplificar seus pipelines de infraestrutura como código (IaC) no AWS.

Principais Benefícios:
Reutilização de Código: Mantenha a lógica do pipeline em um único local (terraform-generic.yml) e reutilize-a para todos os seus serviços.

Consistência: Garanta que todos os seus deployments de infraestrutura sigam o mesmo processo, reduzindo erros e inconsistências.

Flexibilidade: Suporta a implantação de múltiplos serviços com estruturas de diretório Terraform independentes dentro do mesmo repositório.

Gerenciamento de State Centralizado: Utiliza S3 para o backend do state do Terraform e DynamoDB para gerenciamento de locks, garantindo operações seguras em ambientes colaborativos.

Controle Granular: Permite acionar plan, apply ou destroy através de inputs configuráveis.

Integração AWS OIDC: Autentica com a AWS usando OpenID Connect (OIDC), eliminando a necessidade de credenciais de longa duração no GitHub.

📋 Pré-requisitos
Para utilizar este template, você precisará:

Repositório GitHub: Onde seus arquivos Terraform e workflows de GitHub Actions serão armazenados.

Conta AWS: Com as permissões necessárias para criar e gerenciar os recursos.

Configuração AWS OIDC: Configure a confiança OIDC entre seu repositório GitHub e uma Role IAM na AWS. Esta Role deve ter permissões para assumir as Roles específicas de cada ambiente (aws-assume-role-arn).

Role IAM para GitHub Actions: Uma Role (ex: github-actions-pipeline-infra) que as GitHub Actions possam assumir, concedendo permissões para assumir as roles de deployment por ambiente.

Bucket S3 para State Files: Um bucket S3 (ex: cidade-refugio-statefiles) para armazenar os arquivos de estado do Terraform.

Tabela DynamoDB para Locks: Uma tabela DynamoDB (ex: cidade-refugio-terraform-lock) para gerenciamento de locks do Terraform.

🛠️ Configuração do Template
Crie o Diretório de Workflows: Se ainda não existir, crie o diretório .github/workflows/ na raiz do seu repositório.

Adicione o Arquivo do Template: Dentro de .github/workflows/, crie um arquivo chamado terraform-generic.yml e cole o conteúdo do template genérico (conforme fornecido anteriormente).

# .github/workflows/terraform-generic.yml
name: "Terraform Generic Workflow"
on:
  workflow_call:
    inputs:
      environment: { type: string, required: true, description: "..." }
      aws-assume-role-arn: { type: string, required: true, description: "..." }
      aws-region: { type: string, required: true, description: "..." }
      aws-statefile-s3-bucket: { type: string, required: true, description: "..." }
      aws-lock-dynamodb-table: { type: string, required: true, description: "..." }
      service-name: { type: string, required: true, description: "..." }
      terraform-dir: { type: string, required: true, description: "..." }
      destroy: { type: boolean, required: false, default: false, description: "..." }
# ... (restante do código do template)

🚀 Como Usar este Template Genérico
Para implantar um serviço AWS usando este template, você precisará criar um novo arquivo de workflow que "chama" o terraform-generic.yml e passa os parâmetros específicos para o seu serviço e ambiente.

Exemplo: Deployment de Desenvolvimento para "My Web App"
Crie um arquivo como .github/workflows/dev-deploy-my-web-app.yml e adicione o seguinte conteúdo:

# .github/workflows/dev-deploy-my-web-app.yml
name: "DEV Deploy My Web App"

on:
  push:
    branches:
      - develop # Acionado em pushes para a branch 'develop'
    paths:
      # Opcional: Só executa se houver mudanças no diretório específico do Terraform deste serviço
      - 'terraform/my-web-app/**' 

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    uses: ./.github/workflows/terraform-generic.yml # Caminho para o seu workflow genérico
    with:
      environment: dev # Ambiente alvo: 'dev'
      aws-assume-role-arn: "arn:aws:iam::063630845645:role/github-actions-pipeline-infra" # Role para assumir no GitHub Actions
      aws-region: "sa-east-1" # Região AWS
      aws-statefile-s3-bucket: "cidade-refugio-statefiles" # Bucket S3 para state files
      aws-lock-dynamodb-table: "cidade-refugio-terraform-lock" # Tabela DynamoDB para locks
      service-name: "my-web-app" # Nome único do serviço (usado para o path do state file: my-web-app/dev/terraform.tfstate)
      terraform-dir: "terraform/my-web-app" # Caminho do diretório que contém os arquivos .tf do serviço
      destroy: false # Define que este workflow fará um 'plan' e 'apply' (false), não um 'destroy'

Explicação dos Inputs:
environment: O nome do ambiente alvo (ex: dev, homolog, prod). Usado para o workspace do Terraform e para carregar as tfvars do ambiente.

aws-assume-role-arn: O ARN da Role IAM que o GitHub Actions assumirá para se autenticar com a AWS.

aws-region: A região AWS onde os recursos serão implantados.

aws-statefile-s3-bucket: O nome do bucket S3 que armazenará os arquivos de estado do Terraform.

aws-lock-dynamodb-table: O nome da tabela DynamoDB usada para gerenciar o bloqueio de estado do Terraform.

service-name: Um nome único para o serviço ou módulo Terraform que está sendo implantado. Este nome é crucial para criar um caminho de state file exclusivo no S3 (<service-name>/<environment>/terraform.tfstate), evitando conflitos entre diferentes serviços.

terraform-dir: O caminho relativo do repositório para o diretório que contém os arquivos .tf do Terraform para este serviço específico.

destroy: Um valor booleano (true ou false). Se true, o workflow executará terraform destroy. Se false (padrão), ele fará terraform plan e terraform apply.

📁 Estrutura Recomendada do Projeto Terraform
Para aproveitar ao máximo este template, sugerimos a seguinte estrutura de diretórios para seus arquivos Terraform:

.
├── .github/
│   └── workflows/
│       ├── terraform-generic.yml            # O template genérico do pipeline
│       ├── dev-deploy-my-web-app.yml      # Exemplo de chamada para 'my-web-app' em 'dev'
│       └── prod-deploy-another-service.yml  # Exemplo de chamada para outro serviço em 'prod'
└── terraform/
    ├── my-web-app/                       # Diretório Terraform para o serviço "my-web-app"
    │   ├── main.tf
    │   ├── variables.tf
    │   └── envs/                         # Variáveis específicas de ambiente para este serviço
    │       ├── dev/
    │       │   └── terraform.tfvars
    │       └── prod/
    │           └── terraform.tfvars
    └── another-service/                  # Diretório Terraform para "another-service"
        ├── main.tf
        ├── variables.tf
        └── envs/
            ├── dev/
            │   └── terraform.tfvars
            └── prod/
                └── terraform.tfvars

⚠️ Observações Importantes
terraform.tfvars: Certifique-se de que cada diretório de serviço (terraform/<service-name>/envs/<environment>/) contenha um arquivo terraform.tfvars com as variáveis específicas para aquele ambiente.

Permissões: As permissões da Role IAM configurada via OIDC (aws-assume-role-arn) são críticas. Certifique-se de que ela tenha acesso para assumir as roles de deployment e para gerenciar os recursos S3 e DynamoDB do backend.

Segurança: Sempre revise os terraform plan gerados antes de permitir um terraform apply em ambientes de produção. O auto-approve no destroy deve ser usado com extrema cautela.