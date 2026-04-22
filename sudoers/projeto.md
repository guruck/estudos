# 🛡️ Projeto de Auditoria Automatizada de Privilégios (POC)

Este projeto estabelece um ambiente controlado para simular e auditar configurações de privilégios (`sudo`) em sistemas Linux. A solução utiliza containers Docker para isolar o ambiente de coleta (Auditor) do ambiente alvo (Target), garantindo que a auditoria seja realizada de forma programática e segura.

## 🏗️ Arquitetura do Sistema

O projeto é dividido em dois componentes principais orquestrados via **Docker Compose**:

1.  **Target (Alvo):** Um container baseado em `bash:4.4` (Alpine Linux) configurado para simular um servidor real.
    *   **Porta SSH:** 4098 (Segurança por obscuridade e teste de configuração não padrão).
    *   **Cenários de Teste:** Usuários criados com diferentes níveis de risco (UID 0 duplicado, membros de grupos privilegiados e usuários com permissão direta no sudoers).
2.  **Collector (Coletor):** Um container `python:3.12-slim` que atua como a unidade de auditoria.
    *   **Tecnologia:** Python com a biblioteca `Paramiko`.
    *   **Método:** Conexão via chave RSA (sem senhas trafegando na rede).

## 🛠️ Elementos Selecionados e Funcionamento

### 1. Troca Automática de Chaves (Zero Trust)
Para evitar o armazenamento de senhas, o container `target` gera um par de chaves RSA no boot através do script `setup_ssh.sh`.
*   As chaves são compartilhadas via um **volume Docker** (`shared_keys`).
*   O `collector` aguarda a existência da chave privada para iniciar a auditoria, garantindo sincronia entre os containers.

### 2. O Script de Auditoria POSIX (`coletor_com_privilegios.sh`)
Em vez de usar comandos isolados, enviamos um script completo e universal. Ele foi escrito em **POSIX shell** para garantir compatibilidade com qualquer imagem (Debian, Alpine, RHEL, etc).
*   **Identidade vs Autorização:** O script cruza dados do `/etc/passwd` (quem é o usuário) com `/etc/sudoers` (o que ele pode fazer).
*   **Detecção de Grupos:** Diferente de uma busca simples, ele "explode" os grupos do usuário (via `id -Gn`) e verifica se algum desses grupos tem permissão no sudoers (ex: `%root` ou `%admin`).
*   **Normalização de Datas:** Converte o formato "Epoch" do `/etc/shadow` para datas ISO (AAAA-MM-DD), facilitando a leitura por humanos ou bancos de dados.

### 3. Injeção via STDIN (Resiliência de Execução)
No `main.py`, o script Python não tenta passar o código bash como um argumento de comando (o que causaria erros de aspas/escaping).
*   **Processo:** O Python abre um canal `sudo sh` no alvo e injeta o conteúdo do script diretamente no **Standard Input (STDIN)**.
*   **Vantagem:** Isso permite executar scripts complexos sem se preocupar com caracteres especiais ou limites de tamanho de linha de comando do shell.

## 🧪 Cenários de Risco Simulados

O ambiente é populado com vulnerabilidades clássicas de governança para validar a eficácia do coletor:

| Usuário | Cenário de Auditoria | Resultado Esperado |
| :--- | :--- | :--- |
| `martha` | **UID 0 Backdoor** | Identificada como `SIM_ROOT` (Risco Crítico). |
| `jhonas/maria` | **Privilégio Herdado** | Identificados via `GRUPO(root)`. |
| `fabricio` | **Privilégio Direto** | Identificado via `DIRETO` no sudoers. |
| `logon` | **Operador de Auditoria** | Usuário técnico com permissão mínima necessária para coletar dados. |
| `leandro/pedro` | **Baseline** | Usuários comuns sem privilégios (`NAO`). |

## 🚀 Como Executar

1.  **Subir o ambiente:**
    ```bash
    docker-compose up --build
    ```
2.  **O que acontece a seguir:**
    *   O `target` sobe, gera as chaves e cria os usuários.
    *   O `collector` detecta a chave, conecta via SSH na porta 4098.
    *   O relatório consolidado é impresso no console no formato pipe-delimited (`|`):
        `HOSTNAME|OS|USER|UID|FONTE|SHELL|ULTIMA_ALT|EXP_CONTA|GRUPOS|SUDO`

## 📈 Evolução do Projeto
Este modelo serve como base para um pipeline de conformidade contínua, onde os dados impressos pelo Python podem ser enviados para um SIEM (como Splunk ou Elastic) ou salvos em um Data Lake para monitoramento de desvio de configuração (*configuration drift*).

---
*Documento gerado como parte da POC de Segurança e Governança Linux.*

---

No diretório raiz do seu projeto (/estudos/sudoers/), execute o comando abaixo para criar as chaves que serão injetadas:

```bash
ssh-keygen -t rsa -b 4096 -f ./id_rsa -N ""
# Mova cada uma para sua respectiva pasta de build
mv id_rsa collector/
mv id_rsa.pub target/
```
