# Tabela 1: Ficha de Admissão
resource "aws_dynamodb_table" "ficha_admissao" {
  name           = "FichaAdmissao"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "cpf"
  range_key      = "nome"

  attribute {
    name = "cpf"
    type = "S"
  }

  attribute {
    name = "nome"
    type = "S"
  }
}

# Tabela 2: Tabela de Pertences
resource "aws_dynamodb_table" "pertences" {
  name           = "Pertences"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "cpf"
  range_key      = "nome"

  attribute {
    name = "cpf"
    type = "S"
  }

  attribute {
    name = "nome"
    type = "S"
  }

}