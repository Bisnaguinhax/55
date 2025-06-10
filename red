```mermaid
graph TD
    subgraph "1. Fontes de Dados"
        API_BC["API Banco Central (IPCA) 📈"]
        API_OWM["API OpenWeatherMap ☁️"]
        DS_OLIST["Datasets Públicos Olist 📦"]
        SIM_STREAM["Simulador de Stream de Vendas ⚡"]
    end

    subgraph "2. Ingestão e Orquestração (Apache Airflow)"
        AF_WEBSERVER(Airflow Webserver 🌐)
        AF_SCHEDULER(Airflow Scheduler & Workers ⚙️)
        AF_DB[Airflow Metadata DB (PostgreSQL) 🗄️]

        subgraph "DAGs do Airflow"
            DAG_COLETA_SEGURA(dag_01_coleta_segura_v1.py<br><i>Coleta Segura IPCA/Clima</i>)
            DAG_COLETA_VALIDA(dag_coleta_e_validacao_v1.py<br><i>Coleta & Validação Básica</i>)
            DAG_CONSOLIDA_MASK(dag_03_consolidacao_e_mascaramento_v1.py<br><i>Consolidação & Mascaramento PII</i>)
            DAG_SPARK_SEGURO(dag_04_processamento_spark_seguro_v1.py<br><i>Processamento Spark Seguro</i>)
            DAG_VALIDA_GE(dag_05_validacao_segura_v1.py<br><i>Validação Great Expectations</i>)
            DAG_UPLOAD_BRONZE(dag_upload_bronze_minio_v1.py<br><i>Upload para Bronze Layer</i>)
            DAG_UPLOAD_SILVER(dag_upload_silver_minio_v1.py<br><i>Upload para Silver Layer</i>)
            DAG_LIFECYCLE(dag_gerenciamento_lifecycle_v1.py<br><i>Gerenciamento de Ciclo de Vida</i>)
            DAG_MINIO_PG(dag_minio_para_postgresql_v1.py<br><i>Data Lake para Data Mart ETL</i>)
            DAG_CARGA_STAR(dag_06_carrega_star_schema_segura_v1.py<br><i>Carga Star Schema Segura</i>)
        end

        subgraph "Sistema de Segurança Customizado (Plugin Airflow)"
            SEC_MANAGER(AirflowSecurityManager<br><b>Vault Criptografado 🔐</b>)
            AUDIT_LOGGER(AuditLogger<br><i>Log de Auditoria Completa 📝</i>)
            DATA_PROTECTION(DataProtection<br><i>Mascaramento PII 🔒</i>)
            CONN_POOL(SecureConnectionPool<br><i>Conexões Seguras 🔗</i>)
            EXCEPTIONS(Exceções Customizadas ⚠️)
        end
    end

    subgraph "3. Data Lake (MinIO - Object Storage)"
        MINIO_SERVER[MinIO Server ☁️]
        BRONZE_LAYER(Camada Bronze<br><i>Dados Brutos</i>)
        SILVER_LAYER(Camada Silver<br><i>Dados Curados & Mascarados</i>)
        ANALYTICS_LAYER(Camada Analytics<br><i>Processados por Spark</i>)
        COLD_STORAGE(Cold Storage Layer<br><i>Dados Antigos/Arquivados</i>)
    end

    subgraph "4. Processamento & Transformação (Spark)"
        SPARK_CLUSTER[Apache Spark Cluster ✨]
    end

    subgraph "5. Data Warehousing / Data Mart (PostgreSQL)"
        PG_SERVER[PostgreSQL Data Mart 📊]
        DM_CLIENTE(dim_cliente)
        DM_PRODUTO(dim_produto)
        FT_VENDAS(fato_vendas)
        TB_OLIST(dados_olist<br><i>Dados Brutos Olist</i>)
    end

    subgraph "6. Qualidade & Governança de Dados"
        GE_VALIDATION(Great Expectations<br><i>Validação de Dados ✅</i>)
        AUDIT_LOGS_FILES(Arquivos de Log de Auditoria<br><i>audit.csv / system.log</i>)
    end

    %% FLUXOS GERAIS
    API_BC -- Coleta --> DAG_COLETA_SEGURA
    API_OWM -- Coleta --> DAG_COLETA_SEGURA
    DS_OLIST -- Ingestão --> DAG_CONSOLIDA_MASK
    SIM_STREAM -- Eventos --> DAG_SPARK_SEGURO
    SIM_STREAM -- Eventos --> DAG_MINIO_PG

    AF_WEBSERVER -- Acesso UI --> AF_SCHEDULER
    AF_SCHEDULER -- Gerencia --> AF_DB
    AF_SCHEDULER -- Orquestra --> DAG_COLETA_SEGURA
    AF_SCHEDULER -- Orquestra --> DAG_COLETA_VALIDA
    AF_SCHEDULER -- Orquestra --> DAG_CONSOLIDA_MASK
    AF_SCHEDULER -- Orquestra --> DAG_SPARK_SEGURO
    AF_SCHEDULER -- Orquestra --> DAG_VALIDA_GE
    AF_SCHEDULER -- Orquestra --> DAG_UPLOAD_BRONZE
    AF_SCHEDULER -- Orquestra --> DAG_UPLOAD_SILVER
    AF_SCHEDULER -- Orquestra --> DAG_LIFECYCLE
    AF_SCHEDULER -- Orquestra --> DAG_MINIO_PG
    AF_SCHEDULER -- Orquestra --> DAG_CARGA_STAR

    %% FLUXOS DE DADOS PARA MINIO
    DAG_COLETA_SEGURA -- Salva Dados Coletados --> BRONZE_LAYER
    DAG_COLETA_VALIDA -- Salva Dados Validados --> BRONZE_LAYER
    DAG_UPLOAD_BRONZE -- Envia Arquivos Brutos --> BRONZE_LAYER
    DAG_CONSOLIDA_MASK -- Salva Dados Consolidados & Mascarados --> SILVER_LAYER
    DAG_UPLOAD_SILVER -- Promove Dados --> SILVER_LAYER
    SPARK_CLUSTER -- Salva Dados Processados --> ANALYTICS_LAYER

    %% FLUXOS INTER-CAMADAS MINIO
    BRONZE_LAYER -- Processado por DAG --> SILVER_LAYER
    SILVER_LAYER -- Processado por SPARK --> ANALYTICS_LAYER
    BRONZE_LAYER -- Dados Antigos para --> COLD_STORAGE
    DAG_LIFECYCLE -- Move Arquivos --> BRONZE_LAYER
    DAG_LIFECYCLE -- Move Arquivos --> COLD_STORAGE

    %% FLUXOS PARA POSTGRESQL
    ANALYTICS_LAYER -- Leitura para Carga --> DAG_MINIO_PG
    SILVER_LAYER -- Leitura para Carga --> DAG_MINIO_PG
    DAG_MINIO_PG -- Carrega Dados --> TB_OLIST
    TB_OLIST -- Consolidado para --> DAG_CARGA_STAR
    DAG_CARGA_STAR -- Carrega Dimensões/Fatos --> PG_SERVER

    %% FLUXOS DE SEGURANÇA E GOVERNANÇA (CRÍTICO)
    DAG_COLETA_SEGURA -- Acessa Credenciais --> SEC_MANAGER
    DAG_CONSOLIDA_MASK -- Acessa Credenciais --> SEC_MANAGER
    DAG_SPARK_SEGURO -- Acessa Credenciais --> SEC_MANAGER
    DAG_MINIO_PG -- Acessa Credenciais --> SEC_MANAGER
    DAG_CARGA_STAR -- Acessa Credenciais --> SEC_MANAGER
    DAG_LIFECYCLE -- Acessa Credenciais --> SEC_MANAGER
    DAG_UPLOAD_BRONZE -- Acessa Credenciais --> SEC_MANAGER
    DAG_UPLOAD_SILVER -- Acessa Credenciais --> SEC_MANAGER

    SEC_MANAGER -- Provê Credenciais Seguras --> MINIO_SERVER
    SEC_MANAGER -- Provê Credenciais Seguras --> PG_SERVER

    SEC_MANAGER -- Registra Operação --> AUDIT_LOGGER
    AUDIT_LOGGER -- Persiste em --> AUDIT_LOGS_FILES

    DAG_COLETA_SEGURA -- Gera Log --> AUDIT_LOGGER
    DAG_CONSOLIDA_MASK -- Gera Log --> AUDIT_LOGGER
    DAG_VALIDA_GE -- Gera Log --> AUDIT_LOGGER
    DAG_MINIO_PG -- Gera Log --> AUDIT_LOGGER
    DAG_CARGA_STAR -- Gera Log --> AUDIT_LOGGER
    DAG_LIFECYCLE -- Gera Log --> AUDIT_LOGGER
    DAG_UPLOAD_BRONZE -- Gera Log --> AUDIT_LOGGER
    DAG_UPLOAD_SILVER -- Gera Log --> AUDIT_LOGGER

    DAG_CONSOLIDA_MASK -- Aplica Proteção --> DATA_PROTECTION
    DATA_PROTECTION -- Auditoria Detalhada --> AUDIT_LOGGER

    DAG_VALIDA_GE -- Utiliza Expectativas --> GE_VALIDATION
    GE_VALIDATION -- Reporta Resultados --> AUDIT_LOGGER
    DAG_VALIDA_GE -- Falha Crítica --> EXCEPTIONS

    CONN_POOL -- Utiliza Vault --> SEC_MANAGER
    CONN_POOL -- Fornece Engine DB --> PG_SERVER
    CONN_POOL -- Fornece Cliente S3 --> MINIO_SERVER

    %% DETALHES DE DADOS E PROCESSAMENTO ESPECÍFICO
    DAG_CONSOLIDA_MASK -->|Output: dados_consolidados_mascarados.csv| SILVER_LAYER
    DAG_CONSOLIDA_MASK -->|Output: dados_consolidados.csv| DAG_VALIDA_GE
    SPARK_CLUSTER -->|Output: consolidado_vendas_processado.csv| ANALYTICS_LAYER
    DAG_SPARK_SEGURO -- Injeta Variáveis de Ambiente --> SPARK_CLUSTER

    %% Configuração de Estilos e Cores para Melhor Visualização
    classDef default fill:#f7f7f7,stroke:#333,stroke-width:2px,color:#000
    classDef mainNode fill:#E0F7FA,stroke:#00796B,stroke-width:2px,color:#000
    classDef securityNode fill:#FBE9E7,stroke:#D84315,stroke-width:2px,color:#000
    classDef dataLayer fill:#F3E5F5,stroke:#9C27B0,stroke-width:2px,color:#000
    classDef dbNode fill:#FFFDE7,stroke:#FFC107,stroke-width:2px,color:#000
    classDef toolNode fill:#E8F5E9,stroke:#4CAF50,stroke-width:2px,color:#000

    class API_BC,API_OWM,DS_OLIST,SIM_STREAM mainNode
    class AF_WEBSERVER,AF_SCHEDULER,AF_DB mainNode
    class SEC_MANAGER,AUDIT_LOGGER,DATA_PROTECTION,CONN_POOL,EXCEPTIONS securityNode
    class BRONZE_LAYER,SILVER_LAYER,ANALYTICS_LAYER,COLD_STORAGE dataLayer
    class MINIO_SERVER toolNode
    class SPARK_CLUSTER toolNode
    class PG_SERVER,DM_CLIENTE,DM_PRODUTO,FT_VENDAS,TB_OLIST dbNode
    class GE_VALIDATION,AUDIT_LOGS_FILES toolNode
