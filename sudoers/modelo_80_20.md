# 📄 Modelo de Governança de Usuários Sudoers (Linux)

## 🎯 Objetivo

Estabelecer controle sobre concessão, revisão e remoção de privilégios administrativos (`sudo`) em sistemas Linux, mitigando riscos de acesso indevido, escalonamento de privilégio e não conformidade.

---

## ⚠️ Riscos Identificados

* Contas ativas sem vínculo com colaboradores (ex: desligados)
* Acesso privilegiado via grupos sem controle (ex: `sudo`, `wheel`)
* Usuários oriundos de LDAP/AD sem governança local
* Falta de rastreabilidade de ações administrativas
* Escalonamento indevido de privilégios
* Falta de revisão periódica

---

## 🔥 Risco Crítico (Resumo Executivo)

> Um usuário pode manter privilégios de `sudo` mesmo não estando visível no `/etc/passwd`, caso venha de fontes externas (LDAP/AD), resultando em **acesso administrativo não monitorado**.

---

## 🧩 Escopo

Aplica-se a:

* Servidores Linux (físicos e virtuais)
* Ambientes on-premise e cloud
* Usuários locais e centralizados (LDAP/AD)

---

## 🔐 Princípios de Controle

1. **Menor privilégio (Least Privilege)**
2. **Segregação de função**
3. **Rastreabilidade (auditoria)**
4. **Ciclo de vida controlado**
5. **Aprovação formal**

---

## 🔄 Ciclo de Vida do Acesso Sudo

### 1. Solicitação

* Justificativa obrigatória
* Tempo de duração definido
* Aprovação do gestor + TI

### 2. Concessão

* Via grupo (preferencial) ou usuário específico
* Registro em:

  * `/etc/sudoers.d/`
  * ou grupo controlado (ex: `sudo`)

### 3. Uso

* Monitorado via logs:

  * `/var/log/auth.log`
  * `auditd`

### 4. Revisão (obrigatória)

* Periodicidade: **trimestral (mínimo)**
* Validação:

  * usuário ainda precisa do acesso?
  * vínculo ativo?

### 5. Revogação

* Imediata em caso de:

  * desligamento
  * mudança de função
  * expiração do prazo

---

## 👥 Controle de Identidade

### Fontes válidas:

* `/etc/passwd`
* LDAP / Active Directory (via SSSD)

### Regra:

> Todo usuário com sudo deve ser rastreável em uma fonte oficial de identidade.

---

## ⚙️ Boas Práticas Técnicas

### ✔️ Estrutura de sudo

* Usar `/etc/sudoers.d/` (evitar editar arquivo principal)
* Evitar permissões amplas:

```bash
ALL=(ALL) ALL
```

### ✔️ Preferir grupos

```bash
%sudo-admin ALL=(ALL) ALL
```

### ✔️ Evitar:

* usuários diretos no sudoers
* permissões sem restrição de comando

---

## 📊 Auditoria e Monitoramento

### Logs obrigatórios:

* sudo usage
* tentativas falhas

### Ferramentas:

* `auditd`
* SIEM (se disponível)

---

## 🚨 Indicadores de Risco (KPIs)

* % de usuários com sudo sem justificativa
* contas sem uso recente com privilégio
* usuários sem vínculo organizacional
* quantidade de acessos via grupo genérico

---

## 🛡️ Controles Mínimos Recomendados (80/20)

Se implementar só isso, você já reduz a maior parte do risco:

* ✔ Revisão trimestral de sudoers
* ✔ Uso exclusivo de grupos controlados
* ✔ Integração com AD/LDAP + SSSD
* ✔ Log habilitado e revisado
* ✔ Processo formal de aprovação

---

## ❌ Não Conformidades Comuns

* Usuários antigos ainda com sudo
* Uso de `%sudo ALL=(ALL) ALL` sem controle
* Falta de documentação
* Ausência de revisão periódica

---

## 🧠 Conclusão Executiva

A ausência de governança sobre usuários sudoers **não é um risco técnico isolado**, mas sim um risco de **controle de acesso privilegiado**, podendo resultar em:

* incidentes de segurança
* vazamento de dados
* não conformidade com auditorias (ISO 27001, LGPD, etc.)

