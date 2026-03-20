# comandos que podem facilitar a jornada


## /etc/sudoers || /etc/sudoers.d/*

Para capturar de 1 só vez os dados de sudoers sem os comentarios

```bash
sudo cat /etc/sudoers /etc/sudoers.d/* | grep -Ev '^#|^$'
```

Por que tirar o Defaults? Eles configuram o comportamento do sudo (timeout, insultos, etc.), mas não dizem quem tem o privilégio. Limpar isso foca o seu relatório no essencial: USER, GROUP e COMMANDS.

```bash
sudo grep -hEv '^#|^$|^Defaults' /etc/sudoers /etc/sudoers.d/* 2>/dev/null
```

## /etc/passwd

A ordem padrão é: usuário:senha:UID:GID:descrição:home:shell

```bash
cat /etc/passwd | cut -d: -f1,2,3,4  # usuário:senha:UID:GID
```

Para listar usuários, seus IDs e se possuem Shell de login ativo:

```bash
awk -F: '$7 !~ /nologin|false/ {print "Usuário Ativo: " $1 " | UID: " $3 " | Shell: " $7}' /etc/passwd
```

## /etc/group

A ordem padrão é: nome_do_grupo:senha:GID:lista_de_usuários (delimitado por virgula ,)

```bash
cat /etc/group | cut -d: -f1,2,3,4  # grupo:senha:GID:user1,user2,user3
```

## /etc/shadow

Este arquivo é a "mina de ouro" para monitorar a política de segurança. Ele requer privilégios de root para leitura.

A ordem padrão é: usuario:senha:ultima_alteracao:min_dias:max_dias:aviso:inatividade:expiracao:reservado

| Campo | Nome | O que significa na prática |
|---|---|---|
| 1 | Usuário | Nome de login (exato como no /etc/passwd). |
| 2 | Senha | Hash da senha. Se começar com ! ou *, o login por senha está bloqueado. |
| 3 | Última Alteração | Data da última troca de senha (em dias desde 01/01/1970). 0 força a troca no próximo login. |
| 4 | Mínimo de Dias | Quantos dias o usuário deve esperar antes de poder trocar a senha novamente. |
| 5 | Máximo de Dias | Validade da senha. Após esses dias, o usuário é obrigado a trocá-la. |
| 6 | Aviso | Quantos dias antes da senha expirar o sistema começa a emitir alertas no login. |
| 7 | Inatividade | Dias de "tolerância" após a senha expirar. Se não trocar nesse prazo, a conta é bloqueada. |
| 8 | Expiração | Data absoluta (em dias desde 1970) em que a conta expira e para de funcionar. |
| 9 | Reservado | Campo vazio para uso futuro do sistema. |

Campos Relevantes:

  * -f3 (Última alteração): Dias desde 1/1/1970. Se estiver 0, o usuário deve trocar a senha no próximo login.
  * -f8 (Data de Expiração): Se preenchido, a conta será bloqueada nesta data.
  * Contas Bloqueadas: Se o campo da senha (-f2) começar com ! ou *, a conta está desativada.

```bash
sudo cat /etc/shadow | cut -d: -f1,2,3,4,5,6,7,8
```

Dicas para sua Monitoração de Segurança:

* Contas Críticas: Se o campo 5 (Máximo de Dias) estiver como 99999, a senha nunca expira. Para segurança, esse valor deve ser reduzido (ex: 90 dias).
* Contas Abandonadas: Se o campo 8 (Expiração) estiver vazio, a conta é eterna. É recomendável definir datas de expiração para usuários temporários ou terceiros.
* Bloqueio Imediato: Para suspender um usuário sem deletar seus arquivos, o comando passwd -l usuario insere um ! no início do campo 2.
* No campo $2 (que você pegou no seu cut), se o hash começar com $6$, a senha usa criptografia SHA-512 (moderna). Se começar com $1$, é MD5 (antiga/vulnerável). Isso é um excelente item para o seu relatório de segurança


## chage

Comando para exibir de forma mais amigavel a informacao para 1 usuario

```bash
sudo chage -l root

Última mudança de senha                                 : ago 05, 2025
Senha expira                                            : nunca
Senha inativa                                           : nunca
Conta expira                                            : nunca
Número mínimo de dias entre troca de senhas             : 0
Número máximo de dias entre troca de senhas             : 99999
Número de dias de avisos antes da expiração da senha    : 7
```

## "chage -l" vs "/etc/shadow"

tabela de mapeamento direto entre a saída do comando e os campos do arquivo:

| Informação no chage -l | Campo Shadow | Exemplo no Shadow | Como interpretar o dado bruto |
|---|---|---|---|
| Última mudança de senha | $3 | 20305 | Número de dias desde 01/01/1970. (Ex: 20305 = 19/03/2026). |
| Senha expira | $3 + $5 | (Cálculo) | Não existe um campo único. É a soma da Última Mudança ($3) + Máximo ($5). |
| Senha inativa (Grace) | $7 | 30 | Dias de acesso permitido após a senha expirar. Vazio = "Nunca". |
| Conta expira | $8 | 20500 | Data absoluta em dias desde 1970. Vazio = "Nunca". |
| Mínimo de dias p/ troca | $4 | 0 | Número inteiro. Se for 0, pode trocar a qualquer momento. |
| Máximo de dias p/ troca | $5 | 99999 | Número de dias de validade. 99999 é o código para "Nunca". |
| Aviso de expiração | $6 | 7 | Número de dias antes do bloqueio que o aviso aparece. |

---

Como ler o /etc/shadow e "pensar" como o chage:

Para monitoração automatizada, use estas regras de lógica:

   1. A conta está bloqueada?
   * Olhe o Campo $2 (Senha). Se começar com ! ou *, o chage diria que a conta não tem senha ou está trancada.
   2. Quando a senha expira?
   * Se o Campo $5 for 99999, o chage escreve "Nunca".
      * Se for menor que isso, a data de expiração é: (Data do Campo $3) + (Valor do Campo $5).
   3. A conta já expirou?
   * Olhe o Campo $8. Se o número de dias ali for menor que a data de hoje (em dias desde 1970), a conta está desativada.

Exemplo Prático de Conversão (Bash)
Se você vir o número 20305 no campo 3 e quiser saber a data exata sem usar o chage, use este comando:

```bash
date -d "1970-01-01 + 20305 days"
```


## awk, extrair dados da identidade em 1 unica passada

```bash
sudo awk -F: '
  # Primeiro arquivo: /etc/passwd (Identidade e Shell)
  NR==FNR && FILENAME=="/etc/passwd" {
    shell[$1]=$7; uid[$1]=$3; next
  }
  # Segundo arquivo: /etc/shadow (Segurança e Expiração)
  NR==FNR && FILENAME=="/etc/shadow" {
    last_change[$1]=$3; acc_exp[$1]=$8; next
  }
  # Terceiro arquivo: /etc/group (Grupos)
  FILENAME=="/etc/group" {
    # Mapeia quem pertence a grupos extras
    n=split($4, members, ",");
    for(i=1; i<=n; i++) groups[members[i]] = groups[members[i]] $1 ",";
  }
  # No final, cruza tudo baseado nos usuários do passwd
  END {
    printf "%-15s | %-5s | %-15s | %-10s | %-10s | %s\n", "USUARIO", "UID", "SHELL", "DT_ALTERA", "DT_EXPIRA", "GRUPOS_EXTRA";
    for (u in shell) {
        # Formata datas vazias
        d_alt = (last_change[u] == "" ? "N/A" : last_change[u]);
        d_exp = (acc_exp[u] == "" ? "Nunca" : acc_exp[u]);

        printf "%-15s | %-5s | %-15s | %-10s | %-10s | %s\n", u, uid[u], shell[u], d_alt, d_exp, groups[u];
    }
  }' /etc/passwd /etc/shadow /etc/group
```

## bash consolidando arquivos

Sim, você pode consolidar tudo em um único script Bash que utiliza funções internas para processar os arquivos. O Bash puro (usando while read e IFS) é ligeiramente mais lento que o AWK em arquivos gigantescos, mas para os arquivos de sistema (/etc/passwd etc.), a diferença de performance é imperceptível e o script fica muito mais fácil de manter e customizar.

Por que esta abordagem resolve o problema?

   1. Relacionamento em um único loop: O script percorre o passwd e, para cada linha, ele busca as informações correspondentes nos outros arquivos.
   2. Identificação de Sudo: Ele já te diz se o nome do usuário está explicitamente no arquivo de privilégios (SUDO_DIRETO).
   3. Fácil de Correlacionar: Se você ver um usuário com SUDO_DIRETO=NAO, mas ele pertence ao grupo wheel ou sudo (coluna GRUPOS), sua regra de negócio na ponta (SIEM/Excel) já sabe que ele tem privilégio elevado.
   4. Performance em Rede: Você dispara este único arquivo .sh via SSH, ele processa tudo localmente em milissegundos e devolve apenas o texto pronto.

Como usar na monitoração em massa:

via SSH puro:

```bash
ssh usuario@servidor 'sudo bash -s' < monitor_users.sh
```

Dica para a regra de negócio:
Para "explodir" os privilégios, sua monitoração deve considerar "Elevado" se:

* UID == 0
* OU SUDO_DIRETO == SIM
* OU GRUPOS contiver wheel, sudo ou admin.

### Exemplo de Script: monitor_users.sh

```bash
#!/bin/bash

# Verifica se é root (necessário para ler /etc/shadow e sudoers)
if [[ $EUID -ne 0 ]]; then
   echo "Este script deve ser executado como root (sudo)."
   exit 1
fi

echo "USUARIO|UID|SHELL|ULTIMA_ALTERACAO|EXPIRACAO_CONTA|GRUPOS|SUDO_DIRETO"

# 1. Mapeia permissões diretas no sudoers (ignora comentários e linhas vazias)
# Armazena em uma variável para consulta rápida
SUDO_RULES=$(grep -rE '^[^# ]' /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

# 2. Processa o /etc/passwd linha por linha
while IFS=: read -r user pass uid gid info home shell; do

    # Pega dados de expiração no /etc/shadow para este usuário
    shadow_line=$(grep "^${user}:" /etc/shadow)
    last_change=$(echo "$shadow_line" | cut -d: -f3)
    acc_exp=$(echo "$shadow_line" | cut -d: -f8)

    # Formata campos vazios
    [[ -z "$acc_exp" ]] && acc_exp="Nunca"
    [[ -z "$last_change" ]] && last_change="N/A"

    # 3. Mapeia grupos extras no /etc/group
    user_groups=$(grep -E "(^|[,:])${user}(,|$)" /etc/group | cut -d: -f1 | paste -sd "," -)

    # 4. Verifica se o usuário aparece DIRETAMENTE no sudoers (não via grupo)
    if echo "$SUDO_RULES" | grep -q "^${user}[[:space:]]"; then
        has_sudo="SIM"
    else
        has_sudo="NAO"
    fi

    # Resultado formatado (Pipe como delimitador)
    echo "${user}|${uid}|${shell}|${last_change}|${acc_exp}|${user_groups}|${has_sudo}"

done < /etc/passwd
```

### Exemplo de Script: monitor_universal.sh

Esta versão utiliza o comando getent, que é a "ponte" oficial do Linux para enxergar tanto usuários locais (/etc/passwd) quanto usuários de rede (LDAP, Active Directory, NIS).

O que mudou e por que é melhor:

* getent passwd: Agora o loop lê a base de dados do sistema, não o arquivo físico. Se um usuário do Active Directory logou, ele aparecerá aqui. [13]
* Campo FONTE: Adicionei uma lógica que verifica se o usuário existe no /etc/passwd. Se não estiver lá, mas o getent o achou, ele é um usuário de Rede/LDAP. [13]
* id -Gn: Em vez de fazer grep no arquivo de grupos, usei o comando id. Ele é o único que traz todos os grupos de um usuário LDAP de forma confiável. [13]
* Conversão de Datas: Já incluí a lógica de date -d para que seu relatório venha com datas legíveis (DD/MM/AAAA) em vez de números brutos. [14]


```bash
#!/bin/bash

# Garante privilégio de root para ler shadow e sudoers
if [[ $EUID -ne 0 ]]; then
   echo "Erro: Execute como root/sudo para acessar dados de segurança."
   exit 1
fi

echo "USUARIO|UID|FONTE|SHELL|ULTIMA_ALTERACAO|EXPIRACAO_CONTA|GRUPOS|SUDO_DIRETO"

# 1. Mapeia regras ativas no sudoers (recursivo em /etc/sudoers.d/)
SUDO_RULES=$(grep -rE '^[^# ]' /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

# 2. Usa getent para listar TODOS os usuários (Locais + Rede)
getent passwd | while IFS=: read -r user pass uid gid info home shell; do

    # Identifica a fonte do usuário (files = local, ldap/sss = rede)
    fonte=$(getent passwd "$user" | cut -d: -f1,2 --output-delimiter=' ' | awk '{print ($2=="x"?"LOCAL/REDE":"DESCONHECIDO")}')
    # Uma forma mais precisa de ver se é local:
    if grep -q "^${user}:" /etc/passwd; then fonte="LOCAL"; else fonte="REDE/LDAP"; fi

    # 3. Coleta dados de expiração
    # Nota: getent shadow pode não retornar dados de rede (depende da config do LDAP)
    shadow_data=$(getent shadow "$user" 2>/dev/null)
    last_change=$(echo "$shadow_data" | cut -d: -f3)
    acc_exp=$(echo "$shadow_data" | cut -d: -f8)

    # Conversão de datas (Dias Epoch para Humano)
    [[ -n "$last_change" && "$last_change" != "0" ]] && last_change=$(date -d "1970-01-01 + $last_change days" +%d/%m/%Y 2>/dev/null) || last_change="N/A"
    [[ -n "$acc_exp" ]] && acc_exp=$(date -d "1970-01-01 + $acc_exp days" +%d/%m/%Y 2>/dev/null) || acc_exp="Nunca"

    # 4. Mapeia grupos (getent group pega grupos locais e de rede)
    user_groups=$(id -Gn "$user" 2>/dev/null | tr ' ' ',')

    # 5. Verifica privilégio direto no sudoers
    if echo "$SUDO_RULES" | grep -q "^${user}[[:space:]]"; then
        has_sudo="SIM"
    else
        has_sudo="NAO"
    fi

    # Output formatado
    echo "${user}|${uid}|${fonte}|${shell}|${last_change}|${acc_exp}|${user_groups}|${has_sudo}"

done
```

:::warning[observacao]

Considere também validar se há grupos no sudoers (ex: %admin) que não possuem membros locais, o que indicaria gestão de permissões via AD.

:::


### Exemplo de Script: coletor_seguranca.sh

Este script inclui a detecção de Sistema Operacional e metadados do host:

```bash
#!/bin/bash

# Identificação Básica do Servidor
HOSTNAME=$(hostname)
IP_INTERNO=$(hostname -I | awk '{print $1}')
OS_NAME=$(uname -s)
OS_VERSION=$(uname -r)

# Cabeçalho para o DataMesh (O Python pode ignorar se já tiver um fixo)
# HOSTNAME|IP|OS|VERSAO|USUARIO|UID|FONTE|SHELL|ULTIMA_ALT|EXP_CONTA|GRUPOS|SUDO_DIRETO

# 1. Captura Regras de Sudo
SUDO_RULES=$(grep -rE '^[^# ]' /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

# 2. Coleta Universal (Locais + Rede)
getent passwd | while IFS=: read -r user pass uid gid info home shell; do

    # Define Fonte (Local vs Rede)
    if grep -q "^${user}:" /etc/passwd; then fonte="LOCAL"; else fonte="REDE/LDAP"; fi

    # Dados de Expiração (Tratamento para AIX/Solaris/Linux pode variar)
    # No Linux padrão:
    shadow_data=$(getent shadow "$user" 2>/dev/null)
    last_change=$(echo "$shadow_data" | cut -d: -f3)
    acc_exp=$(echo "$shadow_data" | cut -d: -f8)

    # Conversão de Data para Formato ISO (Melhor para DataMesh/SQL)
    if [[ -n "$last_change" && "$last_change" != "0" ]]; then
        d_alt=$(date -d "1970-01-01 + $last_change days" +%Y-%m-%d 2>/dev/null || echo "N/A")
    else
        d_alt="N/A"
    fi

    if [[ -n "$acc_exp" ]]; then
        d_exp=$(date -d "1970-01-01 + $acc_exp days" +%Y-%m-%d 2>/dev/null || echo "9999-12-31")
    else
        d_exp="9999-12-31"
    fi

    # Grupos (Comando 'id' funciona em quase todos os Unices)
    user_groups=$(id -Gn "$user" 2>/dev/null | tr ' ' ',')

    # Privilégio Direto no Sudoers
    if echo "$SUDO_RULES" | grep -q "^${user}[[:space:]]"; then
        has_sudo="SIM"
    else
        has_sudo="NAO"
    fi

    # Linha Final para o CSV
    echo "${HOSTNAME}|${IP_INTERNO}|${OS_NAME}|${OS_VERSION}|${user}|${uid}|${fonte}|${shell}|${d_alt}|${d_exp}|${user_groups}|${has_sudo}"

done
```

:::warning[AIX/Solaris]

O comando date -d e o getent são padrão no Linux. No AIX e Solaris, a sintaxe de data e o local das informações de usuários mudam (ex: /etc/security/passwd no AIX). Ideal é o orquestrador detectar antes o "OS_NAME" e disparar um script específico para Unix legados.

:::

---

## Pontos de atenção para um parque diversificado

Além das particularidades do AIX e Solaris, existem variações importantes em distribuições Linux e BSD que podem causar falhas ou resultados incompletos no script de monitoração.

Principais pontos de atenção para o orquestrador:

1. Disponibilidade do getent

* Onde falha: Distribuições minimalistas (como Alpine Linux, comum em containers Docker) ou sistemas BSD (FreeBSD, OpenBSD) podem não ter o getent instalado por padrão.
* Impacto: O script não conseguirá listar usuários de rede (LDAP).
* Solução: O orquestrador deve verificar a existência do comando (command -v getent) antes de rodar a lógica principal.

2. Sintaxe do comando date (GNU vs BSD)

* Onde falha: macOS e FreeBSD usam a versão BSD do date, que não aceita o parâmetro -d "1970-01-01 + X days".
* Sintaxe BSD: Para converter epoch em data no BSD/macOS, usa-se date -r <epoch>.
* Impacto: Erro de sintaxe na conversão das datas de expiração.

3. Diferenças no hostname -I

* Onde falha: O parâmetro -I (para pegar todos os IPs) é uma extensão do GNU hostname. No RHEL/CentOS 6 ou sistemas Unix mais puros, esse parâmetro não existe.
* Solução: Use ip route get 1 | awk '{print $7}' ou o próprio orquestrador para coletar o IP via socket após a conexão SSH.

4. Localização do sudoers

* Onde falha: Algumas distros customizadas ou instalações de segurança endurecida (Hardened) podem mudar o caminho do arquivo ou restringir o acesso ao diretório /etc/sudoers.d/ mesmo para o root se houver SELinux ou AppArmor mal configurado.
* Impacto: O grep no sudoers retornará vazio, mascarando privilégios.

5. Formato do id -Gn

* Onde falha: Em versões muito antigas do BusyBox (sistemas embarcados), o comando id pode não suportar as flags -G ou -n.
* Impacto: A coluna de grupos viria vazia ou com erro.

Resumo de Compatibilidade para o Orquestrador:

| Componente | Linux (RHEL/Debian/Suse) | Alpine (BusyBox) | BSD / macOS | AIX / Solaris |
|---|---|---|---|---|
| getent | Sim | Opcional | Não (usa pw ou dscl) | Não |
| date -d | Sim | Sim | Não (usa date -r) | Não |
| id -Gn | Sim | Sim | Sim | Parcial |
| /etc/shadow | Sim | Sim | Não (usa master.passwd) | Não |

Recomendação para o Orquestrador:

Faça detectar o SO primeiro (uname -s). Se for Linux, dispare o script de exemplo. Se for qualquer outra coisa, dispare uma versão específica para aquele sistema.

---

### Exemplo de Script: coletor_com_privilegios.sh

Para elevar o nível da auditoria, o script agora identifica não apenas o usuário direto, mas também se ele pertence a qualquer
grupo que tenha permissão de sudo (aquelas linhas que começam com % no arquivo de configuração).
Isso resolve o "ponto cego" de usuários que têm poder de root via grupos de rede (como AD/LDAP).

```bash
#!/bin/bash

# Identificação do Host (Metadados básicos)
HOSTNAME=$(hostname)
OS_NAME=$(uname -s)

# Função Universal de Data (ISO 8601)
convert_days_to_iso() {
    local days=$1
    if [[ -z "$days" || "$days" == "0" || "$days" == "99999" ]]; then echo "9999-12-31"; return; fi
    local seconds=$((days * 86400))
    if date --version >/dev/null 2>&1; then
        date -u -d "@$seconds" +%Y-%m-%d 2>/dev/null || echo "9999-12-31"
    else
        date -u -r "$seconds" +%Y-%m-%d 2>/dev/null || echo "9999-12-31"
    fi
}

# 1. Mapeia Sudoers (Regras Ativas)
SUDO_RULES=$(grep -rE '^[^# ]' /etc/sudoers /etc/sudoers.d/* 2>/dev/null)

# 2. Extrai Grupos com Privilégio (Linhas que começam com %)
SUDO_GROUPS=$(echo "$SUDO_RULES" | grep '^%' | cut -d' ' -f1 | tr -d '%')

# 3. Processamento de Usuários (Getent p/ capturar Local + Rede)
USERS_SOURCE=$(command -v getent >/dev/null && getent passwd || cat /etc/passwd)

echo "$USERS_SOURCE" | while IFS=: read -r user pass uid gid info home shell; do

    # Valida Fonte (Local vs Rede)
    grep -q "^${user}:" /etc/passwd && fonte="LOCAL" || fonte="REDE"

    # Captura Datas de Segurança (Shadow)
    shadow_line=$(command -v getent >/dev/null && getent shadow "$user" 2>/dev/null || grep "^${user}:" /etc/shadow 2>/dev/null)
    dt_alteracao=$(convert_days_to_iso "$(echo "$shadow_line" | cut -d: -f3)")
    dt_expiracao=$(convert_days_to_iso "$(echo "$shadow_line" | cut -d: -f8)")

    # Grupos do Usuário (Lista separada por vírgula)
    user_groups_list=$(id -Gn "$user" 2>/dev/null | tr ' ' ',')

    # --- Lógica de Privilégio Elevado ---
    has_sudo="NAO"

    # Regra 1: Usuário Root (UID 0)
    if [[ "$uid" == "0" ]]; then
        has_sudo="SIM_ROOT"
    # Regra 2: Usuário explícito no sudoers
    elif echo "$SUDO_RULES" | grep -q "^${user}[[:space:]]"; then
        has_sudo="SIM_DIRETO"
    # Regra 3: Usuário pertence a um grupo com sudo (Explode Grupos)
    else
        for g in ${user_groups_list//,/ }; do
            if echo "$SUDO_GROUPS" | grep -qxw "$g"; then
                has_sudo="SIM_VIA_GRUPO($g)"
                break
            fi
        done
    fi

    # Saída CSV Final (Pronta para enriquecimento no Python)
    echo "${HOSTNAME}|${OS_NAME}|${user}|${uid}|${fonte}|${shell}|${dt_alteracao}|${dt_expiracao}|${user_groups_list}|${has_sudo}"
done
```

### Exemplo de Script: coletor_com_privilegios_universal.sh

Para garantir que o script seja portável e rode em qualquer shell (inclusive os mais simples como o do Alpine ou o sh padrão), reescrevi a lógica usando apenas sintaxe POSIX, que é a mais leve e compatível possível.

Principais correções aplicadas:

* Troca de [[ ]] por [ ]: O colchete duplo é exclusivo do Bash/Zsh. O colchete simples funciona em todos os shells Linux/Unix.
* Remoção de ${user_groups_list//,/ }: Substituí pela combinação echo | tr, que é o padrão POSIX para manipular strings.
* Shebang #!/bin/sh: Agora o script avisa ao sistema que usará apenas comandos básicos, evitando conflitos de versão de shell.
* Tratamento de permissões: Os erros de "Permission denied" ocorrem se o script não for rodado como root. Certifique-se de que o orquestrador chame o script com sudo.

Dica para o Orquestrador: Ao salvar o arquivo no servidor remoto, certifique-se de dar permissão de execução: chmod +x coletor.sh.

```sh
#!/bin/sh

# Identificação do Host
HOSTNAME=$(hostname)
OS_NAME=$(uname -s)

# Função de Data Compatível (POSIX)
convert_days_to_iso() {
    days=$1
    if [ -z "$days" ] || [ "$days" = "0" ] || [ "$days" = "99999" ]; then
        echo "9999-12-31"; return
    fi
    seconds=$((days * 86400))
    # Detecta se é GNU date ou BSD date
    if date --version >/dev/null 2>&1; then
        date -u -d "@$seconds" +%Y-%m-%d 2>/dev/null || echo "9999-12-31"
    else
        date -u -r "$seconds" +%Y-%m-%d 2>/dev/null || echo "9999-12-31"
    fi
}

# 1. Mapeia Sudoers
SUDO_RULES=$(grep -shE '^[^# ]' /etc/sudoers /etc/sudoers.d/* 2>/dev/null)
SUDO_GROUPS=$(echo "$SUDO_RULES" | grep '^%' | cut -d' ' -f1 | tr -d '%')

# 2. Fonte de Usuários
if command -v getent >/dev/null 2>&1; then
    USERS_SOURCE=$(getent passwd)
else
    USERS_SOURCE=$(cat /etc/passwd)
fi

# 3. Processamento linha por linha (Compatível com qualquer Shell)
echo "$USERS_SOURCE" | while IFS=: read -r user pass uid gid info home shell; do

    # Valida Fonte
    if grep -q "^${user}:" /etc/passwd 2>/dev/null; then fonte="LOCAL"; else fonte="REDE"; fi

    # Shadow Data
    if command -v getent >/dev/null 2>&1; then
        shadow_line=$(getent shadow "$user" 2>/dev/null)
    else
        shadow_line=$(grep "^${user}:" /etc/shadow 2>/dev/null)
    fi

    d_alt=$(echo "$shadow_line" | cut -d: -f3)
    d_exp=$(echo "$shadow_line" | cut -d: -f8)

    dt_alteracao=$(convert_days_to_iso "$d_alt")
    dt_expiracao=$(convert_days_to_iso "$d_exp")

    # Grupos (Lista separada por vírgula)
    user_groups_list=$(id -Gn "$user" 2>/dev/null | tr ' ' ',')

    # --- Lógica de Privilégio Definitiva captura multiplos delimitando por ','---
    privs=""

    if [ "$uid" = "0" ]; then
        privs="SIM_ROOT"
    fi

    # Busca o usuário direto no sudoers (ignora espaços/tabs)
    if echo "$SUDO_RULES" | grep -qE "^${user}[[:space:]]+"; then
        [ -n "$privs" ] && privs="$privs,"
        privs="${privs}DIRETO"
    fi

    # Loop de grupos: verifica se o grupo do usuário está no sudoers (com %)
    for g in $(echo "$user_groups_list" | tr ',' ' '); do
        # Procura por "%nome_do_grupo" no início da linha do sudoers
        if echo "$SUDO_RULES" | grep -qE "^%${g}[[:space:]]+"; then
            [ -n "$privs" ] && privs="$privs,"
            privs="${privs}GRUPO($g)"
        fi
    done

    [ -z "$privs" ] && has_sudo="NAO" || has_sudo="$privs"


    echo "${HOSTNAME}|${OS_NAME}|${user}|${uid}|${fonte}|${shell}|${dt_alteracao}|${dt_expiracao}|${user_groups_list}|${has_sudo}"
done
```

## Considerações Finais

Validar estes 4 cenários críticos que costumam "quebrar" scripts de auditoria:

1. Usuário com Espaço no Nome: (Raro, mas acontece em AD/LDAP) – Verifique se o IFS e as aspas tratam nomes como Nome Sobrenome.
2. Sudoers com Aliases: Se o ambiente usa User_Alias ou Runas_Alias, lembre-se que o grep simples no arquivo não os "enxerga" (eles não começam com %).
3. Arquivos Vazios em /etc/sudoers.d/: Garanta que o grep não gere erro de "arquivo não encontrado" se houver um diretório vazio.
4. Usuário de Rede sem Shell: Verifique se o script se comporta bem quando o getent traz usuários com shell /bin/false ou /usr/sbin/nologin.

Dica de Ouro: Se precisar de precisão cirúrgica nos Aliases mais tarde, evoluir o script para usar o comando sudo -l -U <usuario> apenas para os casos onde o grep inicial der negativo.

