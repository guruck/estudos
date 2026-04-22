import paramiko
import time
import os

def run_audit():
    host = "target"
    port = 4098
    username = "logon"
    key_path = "/root/.ssh/id_rsa"

    # Caminho do script de auditoria que será enviado
    script_local_path = "coletor_com_privilegios.sh"

    with open(script_local_path, 'r') as f:
        audit_script_content = f.read()

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    private_key = paramiko.RSAKey.from_private_key_file(key_path)

    try:
        ssh.connect(host, port=port, username=username, pkey=private_key)
        print(f"Conectado ao {host} na porta {port}")

        # Executa 'sudo sh' e envia o conteúdo do script via stdin
        # Isso evita erros de aspas/escaping no shell
        stdin, stdout, stderr = ssh.exec_command("sudo sh")
        stdin.write(audit_script_content)
        stdin.flush()
        stdin.channel.shutdown_write() # Sinaliza fim do script para o shell

        output = stdout.read().decode()
        errors = stderr.read().decode()
        print("\n--- RELATÓRIO DE AUDITORIA ---")
        print(output)

        if errors:
            print(f"Erros encontrados:\n{errors}")

    except Exception as e:
        print(f"Erro na conexão: {e}")
    finally:
        ssh.close()

if __name__ == "__main__":
    run_audit()
