## 🔑 Como funciona o `sudo` no Linux (base essencial)

O `sudo` **não funciona isoladamente** — ele depende de dois pilares:

1. **Identidade do usuário**

   * Vem de:

     * `/etc/passwd` (local), ou
     * LDAP / AD / NSS (remoto)
   * Se o usuário **não existe aqui, ele não existe para o sistema**

2. **Autorização (sudoers)**

   * Definida em:

     * `/etc/sudoers`
     * `/etc/sudoers.d/*`
   * Pode referenciar:

     * usuários
     * grupos (ex: `%wheel`, `%sudo`)

👉 Ou seja:
**sudo = identidade válida + regra de autorização**

---

## ⚠️ Pergunta principal:

### “Um usuário que não existe no `/etc/passwd` pode usar sudo?”

👉 **Resposta curta: NÃO.**

Se o usuário **não for resolvido pelo sistema (NSS)**, ele:

* não consegue logar
* não consegue executar `sudo`
* não existe contexto de UID

---

## 🚨 Onde está o risco REAL (o que geralmente pega)

O problema **não é usuário inexistente**, e sim:

### 1. 🧩 Usuários “fantasmas” via integração externa

Se você usa:

* LDAP / Active Directory / SSSD

👉 Um usuário pode:

* **não estar no `/etc/passwd`**
* mas **existir no diretório corporativo**

✔ Nesse caso, ele **EXISTE para o sistema**

💥 Risco:

* Conta ativa no AD esquecida
* Continua com acesso sudo

---

### 2. 👥 Grupos no sudoers

Exemplo:

```
%sudo ALL=(ALL) ALL
```

👉 Qualquer usuário no grupo `sudo` ganha privilégio

💥 Risco:

* Governança ruim de grupos
* Usuário herdando acesso sem controle direto

---

### 3. 🔐 UID reutilizado

Mesmo que o nome suma:

* UID pode permanecer ou ser reutilizado

💥 Risco:

* permissões em arquivos
* scripts automatizados
* logs inconsistentes

---

### 4. 📝 Falta de auditoria e ciclo de vida

Sem processo:

* usuários não são removidos
* acessos não são revisados
* exceções viram regra

💥 Esse é o maior risco organizacional

---

## 🔗 Como o sistema “relaciona” tudo

Fluxo simplificado:

1. Usuário executa `sudo`
2. Sistema consulta:

   * NSS (`/etc/passwd`, LDAP, etc.)
3. Valida identidade (UID)
4. Consulta regras em `/etc/sudoers`
5. Verifica:

   * usuário OU grupo
6. Libera ou bloqueia

---

## 🧠 Resumo 80/20 (o que você precisa guardar)

* ❌ Usuário inexistente no sistema → não usa sudo
* ⚠️ Usuário pode existir fora do `/etc/passwd` (LDAP/AD)
* 🔥 Maior risco = **governança ruim**, não falha técnica
* 🎯 sudo depende de:

  * identidade válida (NSS)
  * regra explícita (sudoers)

---

## 🛡️ Controles essenciais (alto valor, baixo esforço)

Se você quiser resolver 80% do problema na empresa:

1. **Centralizar identidade (LDAP/AD + SSSD)**
2. **Controlar grupos privilegiados (`sudo`, `wheel`)**
3. **Revisão periódica de acessos**
4. **Logs de sudo (`/var/log/auth.log` ou auditd)**
5. **Usar `sudoers.d` (evitar bagunça no arquivo principal)**

