import os

# Diretórios para procurar pelos arquivos a serem corrigidos
DIRECTORIES_TO_SCAN = ["dags", "plugins", "scripts"]

# A linha que o script de shell já corrigiu
TARGET_LINE = "SECRET_KEY = os.getenv('SECURITY_VAULT_SECRET_KEY')"

# O bloco de validação que quero inserir
VALIDATION_BLOCK = [
    'if not SECRET_KEY:',
    '    raise ValueError("ERRO CRÍTICO: A variável de ambiente \'SECURITY_VAULT_SECRET_KEY\' não está definida.")'
]

def refine_file(file_path):
    """
    Abre um arquivo, verifica se precisa da validação e a insere se necessário.
    O script é idempotente: não fará alterações se já estiver corrigido.
    """
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        new_lines = []
        modified = False
        i = 0
        while i < len(lines):
            current_line = lines[i].strip()
            new_lines.append(lines[i])

            # Verifica se a linha atual é a que quero
            if current_line == TARGET_LINE:
                # Olha a próxima linha para ver se a validação já existe
                if (i + 1 >= len(lines)) or VALIDATION_BLOCK[0] not in lines[i + 1]:
                    # Insere o bloco de validação com a indentação correta
                    new_lines.append('\n') # Adiciona uma linha em branco para espaçamento
                    new_lines.append(VALIDATION_BLOCK[0] + '\n')
                    new_lines.append(VALIDATION_BLOCK[1] + '\n')
                    print(f"  -> Bloco de validação inserido em: {file_path}")
                    modified = True
            i += 1
        
        # Se o arquivo foi modificado, salva as alterações
        if modified:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(new_lines)
            return True

    except Exception as e:
        print(f"  -> Erro ao processar o arquivo {file_path}: {e}")
    
    return False

def main():
    """Função principal para encontrar e refinar todos os arquivos necessários."""
    print("🚀 Iniciando script de refinamento final do projeto...")
    print("Procurando arquivos que usam a SECRET_KEY para adicionar validação...")
    
    files_processed = 0
    files_changed = 0

    for directory in DIRECTORIES_TO_SCAN:
        for root, _, files in os.walk(directory):
            for file in files:
                if file.endswith(".py"):
                    file_path = os.path.join(root, file)
                    try:
                        # Apenas processa arquivos que contenham a linha alvo
                        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                            if TARGET_LINE in f.read():
                                files_processed += 1
                                if refine_file(file_path):
                                    files_changed += 1
                    except Exception:
                        continue # Ignora arquivos que não pode ler

    print("\n-------------------------------------")
    if files_changed > 0:
        print(f"✅ Sucesso! {files_changed} arquivo(s) foram atualizados com o bloco de validação.")
    else:
        print("✅ Verificação concluída. Nenhum arquivo precisou de modificação (provavelmente já estavam corretos).")
    print("-------------------------------------")


if __name__ == "__main__":
    main()
