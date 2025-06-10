# -*- coding: utf-8 -*-
"""
Script de Inicialização do Sistema de Vault de Segurança

Este módulo é responsável pela configuração inicial do vault de segurança do Airflow,
preenchendo com as credenciais necessárias para operação dos DAGs em ambiente de produção.
O script segue as melhores práticas de segurança, evitando hardcoding de credenciais.

"""

import os
import sys
from dotenv import load_dotenv

# === CONFIGURAÇÃO DE AMBIENTE E PATHS ===
# Encontra a raiz do projeto para carregar módulos e o .env corretamente
# Esta abordagem garante que o script funcione independentemente do diretório de execução
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

# Carrega as variáveis de ambiente do arquivo .env na raiz do projeto
# Utiliza path absoluto para garantir que o arquivo seja encontrado
load_dotenv(dotenv_path=os.path.join(project_root, '.env'))

# === IMPORTAÇÃO DE MÓDULOS CUSTOMIZADOS ===
# Importa os módulos de segurança desenvolvidos para o projeto
from plugins.security_system.vault import AirflowSecurityManager
from plugins.security_system.audit import AuditLogger

# === CLASSE DE LOGGING SIMPLIFICADO ===
# Logger simples para feedback no console durante a execução do script
# Implementação minimalista para não depender de configurações externas de logging
class SimpleLogger:
    """
    Classe de logging simplificada para operações de setup.
    
    Fornece interface básica de logging sem dependências externas,
    adequada para scripts de inicialização e configuração.
    """
    
    def info(self, msg): 
        """Registra mensagens informativas"""
        print(f"INFO - {msg}")
    
    def warning(self, msg): 
        """Registra mensagens de aviso"""
        print(f"WARN - {msg}")
    
    def error(self, msg): 
        """Registra mensagens de erro"""
        print(f"ERROR - {msg}")

def setup_secrets():
    """
    Configura e popula o vault de segurança com credenciais do ambiente.
    
    Este função implementa o processo de inicialização do sistema de vault,
    lendo credenciais das variáveis de ambiente e armazenando-as de forma
    segura e criptografada no vault do sistema.
    
    Características de segurança implementadas:
    - Não há hardcoding de credenciais no código
    - Validação de variáveis de ambiente obrigatórias
    - Criptografia transparente das credenciais
    - Logging de auditoria para conformidade
    - Tratamento de erros e falhas graciosamente
    
    Raises:
        SystemExit: Quando variáveis críticas de ambiente não são encontradas
    """
    
    # Inicializa sistema de logging
    logger = SimpleLogger()
    
    # === VALIDAÇÃO DE CONFIGURAÇÃO CRÍTICA ===
    # Verifica se a chave mestra do vault foi configurada
    secret_key = os.getenv('SECURITY_VAULT_SECRET_KEY')
    if not secret_key:
        logger.error("ERRO CRÍTICO: A variável 'SECURITY_VAULT_SECRET_KEY' não foi encontrada no arquivo .env.")
        logger.error("Esta chave é essencial para a criptografia do vault. Configure antes de prosseguir.")
        sys.exit(1)
    
    # === INICIALIZAÇÃO DO SISTEMA DE VAULT ===
    # Define o caminho para o arquivo de dados do vault
    vault_path = os.path.join(project_root, 'plugins', 'security_system', 'vault_data.json')
    
    # Instancia o gerenciador de segurança com auditoria habilitada
    sec_manager = AirflowSecurityManager(
        vault_file=vault_path,
        secret_key=secret_key,
        audit_logger=AuditLogger(logger, log_to_file=False)
    )
    
    # === MAPEAMENTO DE CREDENCIAIS ===
    # Dicionário de segredos a serem adicionados ao vault
    # Organiza todas as credenciais necessárias para operação dos DAGs
    secrets_to_add = {
        # API Keys para serviços externos
        "openweathermap_api_key": os.getenv("OPENWEATHERMAP_API_KEY"),
        
        # Configurações do MinIO (Object Storage)
        "minio_endpoint_url": "http://minio:9000",  # Endpoint interno do Docker
        "minio_access_key": os.getenv("MINIO_ROOT_USER"),
        "minio_secret_key": os.getenv("MINIO_ROOT_PASSWORD"),
        
        # Configurações do PostgreSQL (Metastore do Airflow)
        "postgres_user": os.getenv("POSTGRES_USER"),
        "postgres_password": os.getenv("POSTGRES_PASSWORD"),
        "postgres_host": "postgres",  # Nome do serviço Docker
        "postgres_port": "5432",     # Porta padrão PostgreSQL
        "postgres_db": "airflow"     # Database do Airflow
    }
    
    # === PROCESSO DE INSERÇÃO DE SEGREDOS ===
    logger.info("Iniciando a configuração de segredos no vault...")
    logger.info(f"Total de {len(secrets_to_add)} credenciais para processar")
    
    # Itera sobre cada credencial, validando e inserindo no vault
    for key, value in secrets_to_add.items():
        # Validação de integridade: pula credenciais vazias ou não definidas
        if not value:
            logger.warning(f"A chave '{key}' não foi encontrada no .env ou está vazia. Pulando.")
            continue
        
        # Armazena o segredo no vault com criptografia automática
        sec_manager.set_secret(key, value)
        logger.info(f"Segredo '{key}' adicionado/atualizado com sucesso.")
    
    # === FINALIZAÇÃO DO PROCESSO ===
    logger.info("\nSetup de segredos do vault concluído!")
    logger.info("O sistema de vault está pronto para uso pelos DAGs do Airflow.")

# === PONTO DE ENTRADA DO SCRIPT ===
# Executa a configuração apenas quando o script é chamado diretamente
if __name__ == "__main__":
    setup_secrets()
