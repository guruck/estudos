# 📋 Resumo Executivo: Auditoria de Privilégios em Larga Escala

## 1. Gestão de Chaves e Autenticação (SSH)
Em um cenário corporativo, o uso de volumes compartilhados (como na POC) é impossível. A distribuição de chaves RSA deve seguir padrões de infraestrutura moderna:

*   **Distribuição via IaC:** Utilizar ferramentas como **Ansible, Puppet ou Terraform** para injetar a chave pública do coletor no arquivo `authorized_keys` de todos os servidores alvo.
*   **SSH Certificates (Recomendado):** Em vez de chaves estáticas, utilizar uma **SSH Certificate Authority (CA)** (ex: HashiCorp Vault). O Coletor solicita um certificado de curta duração, que é aceito por todos os servidores que confiam na CA, eliminando o risco de chaves perdidas ou permanentes.
*   **Bastion/Jump Hosts:** Em redes segmentadas, os coletores devem passar por um Bastion, centralizando o túnel de auditoria.

## 2. Permissões e Segurança do Executor
Para que o coletor funcione sem comprometer a segurança do parque, o usuário auditor (ex: `logon`) deve seguir o princípio do privilégio mínimo:

*   **Conexão:** Acesso via SSH limitado ao IP de origem dos containers Coletores.
*   **Execução via Sudo:** O usuário não precisa de `ALL=(ALL) ALL`. Ele deve ter permissão `NOPASSWD` apenas para os comandos necessários ou para o interpretador que executa o script de auditoria:
    *   Exemplo de regra: `auditor_bot ALL=(root) NOPASSWD: /usr/bin/python3 *, /bin/sh -c *`
*   **Restrição de Escrita:** O diretório onde o script é executado (geralmente `/tmp` ou via pipe direto no `stdin`) deve ser montado com `noexec` se possível, ou limpo imediatamente após a execução.

## 3. Arquitetura Escalável (N Containers Coletores)
Para auditar milhares de servidores de forma eficiente, a abordagem "linear" (um servidor por vez) deve ser substituída por um modelo de **Worker Queue**:

### Componentes da Solução:
1.  **Inventory Service:** Um banco de dados ou API que contém a lista atualizada de todos os servidores ativos (CMDB).
2.  **Message Broker (Fila):** Utilizar **RabbitMQ ou Redis**. O Inventory Service publica "tarefas" (IP do servidor alvo) na fila.
3.  **Collector Fleet (Workers):** $N$ containers Coletores rodando em um cluster (Kubernetes/ECS). Cada container consome uma tarefa da fila, executa a auditoria e devolve o resultado.
4.  **Centralized Sink:** Os coletores não imprimem no console, mas enviam o JSON resultante para um **Elasticsearch (ELK)**, **Splunk** ou um bucket **S3** para análise histórica e conformidade.

### Vantagens dessa Abordagem:
*   **Paralelismo:** Se você tem 1.000 servidores e 10 coletores, a auditoria termina 10x mais rápido.
*   **Resiliência:** Se um coletor falhar, a tarefa volta para a fila e outro container assume.
*   **Observabilidade:** É possível monitorar o tempo de resposta e falhas de conexão em tempo real.

## 4. Matriz de Decisão: Push vs. Pull

| Critério | Modelo Push (Atual) | Modelo Pull (Agente) |
| :--- | :--- | :--- |
| **Instalação** | Zero Agent (apenas SSH/Sudo) | Requer instalação de agente em cada máquina |
| **Escalabilidade** | Limitada pelo throughput do Coletor | Extremamente alta (cada máquina se reporta) |
| **Complexidade** | Média (requer gestão de chaves SSH) | Alta (requer gestão de versões do agente) |
| **Ideal para:** | Auditorias pontuais e conformidade | Monitoramento em tempo real de mudanças |

---
**Conclusão:** Para a escala mencionada, a melhor abordagem é manter o modelo **Agentless (Push)** via Python/Paramiko, mas transformando os Coletores em **Workers assíncronos** que consomem uma fila de inventário, utilizando certificados SSH de curta duração para autenticação.
```

Essa estrutura resolve o problema da "confiança" (distribuição de chaves) e da "performance" (escala horizontal com múltiplos containers). O uso de uma fila de mensagens permite que você controle exatamente quantos containers quer rodar sem sobrecarregar a rede ou os servidores alvo.


