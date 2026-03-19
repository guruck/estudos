# 🛡️ Governança de Acesso Privilegiado (SUDO) em Linux

---

## 🎯 Objetivo

Estabelecer um modelo controlado, auditável e seguro para concessão, uso e revogação de privilégios `sudo` em ambientes Linux.

---

## ⚠️ Risco Executivo (Resumo)

A ausência de governança pode permitir que usuários — inclusive oriundos de LDAP/AD e não visíveis em `/etc/passwd` — mantenham privilégios administrativos ativos sem controle, resultando em:

* Acesso indevido a sistemas críticos
* Escalonamento de privilégio
* Falhas de auditoria e compliance
* Incidentes de segurança

---

## 🧩 Escopo

* Servidores Linux (on-premise e cloud)
* Contas locais e centralizadas (LDAP/AD via SSSD)
* Times técnicos e terceiros

---

## 🔐 Princípios

* Menor privilégio (Least Privilege)
* Segregação de função (SoD)
* Rastreabilidade (accountability)
* Aprovação formal
* Revisão periódica

---

# 🔄 Ciclo de Vida do Acesso SUDO

## 1. Solicitação

* Abertura via sistema (ticket)
* Justificativa obrigatória
* Definição de prazo (tempo limitado)

## 2. Aprovação

* Gestor direto
* Segurança da Informação (quando aplicável)

## 3. Concessão

* Inclusão em grupo controlado OU regra em `/etc/sudoers.d/`
* Registro da ação (ticket + log técnico)

## 4. Uso

* Monitoramento contínuo via logs

## 5. Revisão

* Frequência mínima: trimestral

## 6. Revogação

* Automática (expiração) OU manual:

  * desligamento
  * mudança de função

---

# 👥 Matriz RACI

| Atividade        | Solicitante | Gestor | TI/Infra | Segurança |
| ---------------- | ----------- | ------ | -------- | --------- |
| Solicitar acesso | R           | A      | C        | C         |
| Aprovar acesso   |             | R      |          | A         |
| Conceder acesso  |             |        | R        | C         |
| Monitorar uso    |             |        | R        | A         |
| Revisar acessos  |             | R      | C        | A         |
| Revogar acesso   |             | A      | R        | C         |

Legenda:

* R = Responsible
* A = Accountable
* C = Consulted

---

# 🔁 Fluxo Operacional (Pseudo-BPMN)

```
[Solicitação]
     ↓
[Validação de Justificativa]
     ↓
[Aprovação Gestor]
     ↓
[Aprovação Segurança (opcional)]
     ↓
[Concessão via Grupo/Sudoers]
     ↓
[Registro + Log]
     ↓
[Monitoramento Contínuo]
     ↓
[Revisão Trimestral]
     ↓
[Revogar ou Manter]
```

---

# ⚙️ Padrões Técnicos

## ✔️ Estrutura recomendada

* Utilizar:

  * `/etc/sudoers.d/`
* Evitar edição direta de:

  * `/etc/sudoers`

## ✔️ Exemplo correto (grupo controlado)

```bash
%sudo-admin ALL=(ALL) ALL
```

## ❌ Evitar

```bash
ALL=(ALL) ALL
```

ou concessões diretas sem controle.

---

# 🔍 Checklist de Auditoria

## Identidade

* [ ] Usuários existem em fonte oficial (LDAP/AD ou local)
* [ ] Não existem contas órfãs
* [ ] UID consistente

## Autorização

* [ ] Uso de grupos ao invés de usuários diretos
* [ ] Privilégios mínimos necessários
* [ ] Regras documentadas

## Governança

* [ ] Existe processo formal
* [ ] Revisão periódica realizada
* [ ] Evidência de aprovação

## Logs

* [ ] `sudo` log habilitado
* [ ] Logs centralizados (SIEM ou similar)
* [ ] Retenção adequada

---

# 📊 Indicadores (KPIs)

* % usuários com sudo sem justificativa
* % acessos não revisados no prazo
* nº contas inativas com privilégio
* nº acessos via grupos genéricos

---

# 🛠️ Procedimentos Operacionais

## 🔹 Listar usuários com sudo

```bash
getent group sudo
getent group wheel
```

---

## 🔹 Listar regras de sudo

```bash
cat /etc/sudoers
ls /etc/sudoers.d/
```

---

## 🔹 Verificar usuário específico

```bash
sudo -l -U usuario
```

---

## 🔹 Validar origem do usuário

```bash
getent passwd usuario
```

---

# 🤖 Script Básico de Auditoria

```bash
#!/bin/bash

echo "==== Usuários com UID válido ===="
getent passwd | cut -d: -f1

echo ""
echo "==== Grupos privilegiados ===="
getent group sudo
getent group wheel

echo ""
echo "==== Arquivos sudoers.d ===="
ls -l /etc/sudoers.d/

echo ""
echo "==== Verificação de sudo por usuário ===="
for user in $(getent passwd | cut -d: -f1); do
    sudo -l -U $user 2>/dev/null | grep -q "ALL" && echo "Usuário com sudo: $user"
done
```

---

# 🚨 Principais Vulnerabilidades

* Usuários de AD ativos sem controle local
* Grupos amplos (`%sudo ALL=(ALL) ALL`)
* Falta de expiração de acesso
* Ausência de revisão periódica
* Logs não monitorados

---

# 🧠 Conclusão

O risco não está na tecnologia `sudo`, mas na ausência de governança sobre:

* identidade
* autorização
* ciclo de vida

A implementação deste modelo reduz significativamente:

* riscos de segurança
* falhas em auditorias
* acessos indevidos

---

# 📎 Próximos Passos

* Implementar revisão trimestral
* Mapear todos os usuários com sudo
* Migrar permissões para grupos controlados
* Integrar logs com SIEM (se disponível)
* Formalizar política corporativa

---
