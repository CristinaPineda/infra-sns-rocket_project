# Projeto Rocket: Arquitetura de Processamento de Dados Assíncrono na AWS

---

### **Introdução**

O **Projeto Rocket** é uma arquitetura de referência para a criação de um pipeline de processamento de dados assíncrono e robusto, utilizando serviços gerenciados da AWS. O principal objetivo é garantir um fluxo de trabalho eficiente, escalável e resiliente, onde a integridade dos dados e a idempotência dos processos são asseguradas desde a origem da mensagem até a execução final do job de ETL.

### **Conceitos Chave da Arquitetura**

* **Desacoplamento:** Os serviços são independentes, permitindo que falhas em um componente não afetem o fluxo de trabalho como um todo.
* **Idempotência:** Um mecanismo para garantir que uma operação possa ser executada múltiplas vezes sem causar efeitos colaterais indesejados. No Projeto Rocket, isso previne que o mesmo job de ETL seja acionado mais de uma vez.
* **Infraestrutura como Código (IaC):** A infraestrutura é gerenciada e provisionada via código, usando ferramentas de CI/CD como o GitHub Actions para garantir consistência e rastreabilidade nas implantações.
* **Observabilidade:** O sistema é totalmente monitorado, com logs e métricas centralizados, permitindo a identificação rápida de problemas e a análise do desempenho.

### **Arquitetura e Fluxo de Dados**

A arquitetura do Projeto Rocket é composta por uma sequência de serviços AWS que orquestram o fluxo de processamento:

1.  **Publicação da Mensagem (Amazon SNS):** O fluxo começa com um produtor de dados (aplicação, serviço ou automação) que publica uma mensagem em um **Tópico SNS**. Isso serve como o ponto de entrada da arquitetura, desacoplando o produtor do consumidor da mensagem.

2.  **Enfileiramento da Mensagem (Amazon SQS):** O **Tópico SNS** envia automaticamente a mensagem para uma **Fila SQS**. A fila atua como um buffer, garantindo que a mensagem não seja perdida caso o serviço de processamento (AWS Lambda) esteja ocupado ou indisponível.

3.  **Processamento e Validação (AWS Lambda e S3):** Uma **Função Lambda** é acionada sempre que uma nova mensagem chega à fila SQS. A lógica da função é a seguinte:
    * Ela lê a mensagem e extrai um **ID de transação único**.
    * Antes de qualquer ação, a Lambda verifica a **integridade dos processos** consultando um **bucket S3** dedicado.
    * Se o ID já tiver sido processado (indicado pela presença de um objeto com esse ID no bucket S3), a função encerra a execução, garantindo a **idempotência**.
    * Se o ID for novo, a Lambda armazena-o no S3 para marcar o evento como processado.

4.  **Início do Job de ETL (AWS Glue):** Após a validação de idempotência, a **Função Lambda** aciona a API do **AWS Glue** para iniciar um job de ETL, passando os parâmetros necessários extraídos da mensagem SQS. O **Job Glue** executa a lógica de transformação dos dados, como leitura de arquivos, processamento e gravação em um destino final.

### **Fluxo de Implementação (CI/CD)**

A implantação do Projeto Rocket é totalmente automatizada, utilizando o **GitHub Actions** como ferramenta de CI/CD.

* **Infraestrutura como Código (IaC):** Todos os serviços AWS são definidos em um template de código (ex: **AWS CloudFormation**).
* **Automação do Deploy:** Um workflow no GitHub Actions é acionado em cada `push` para o repositório. O workflow se conecta de forma segura à AWS, lê o template IaC e provisiona ou atualiza a infraestrutura, garantindo que o ambiente seja sempre consistente.

### **Componentes e Ferramentas**

| Categoria | Serviço/Ferramenta | Função no Projeto |
| :--- | :--- | :--- |
| **AWS Services** | **SNS** | Publicação de mensagens assíncronas. |
| | **SQS** | Fila de mensagens para desacoplamento. |
| | **Lambda** | Lógica de negócios e validação de idempotência. |
| | **S3** | Armazenamento de IDs para idempotência e dados de processamento. |
| | **Glue** | Execução de jobs de ETL de forma serverless. |
| | **CloudWatch** | Monitoramento, métricas e centralização de logs. |
| **DevOps** | **GitHub Actions** | Automação do pipeline de CI/CD. |
| | **CloudFormation** | Definição da infraestrutura como código (IaC). |

### **Benefícios do Projeto**

* **Escalabilidade e Resiliência:** A arquitetura se adapta automaticamente à carga de trabalho e é resiliente a falhas.
* **Redução de Custo:** Pagamento por uso (serverless), sem a necessidade de manter servidores em operação constante.
* **Confiabilidade:** A idempotência e o desacoplamento garantem a integridade dos dados e a consistência do processamento.
* **Manutenibilidade:** A gestão da infraestrutura via código simplifica as atualizações e a manutenção do ambiente.