#!/bin/bash

# Garante que grupos existam (Alpine/Bash image)
# 1. Criação de usuários de teste conforme projetoBase.md
# 2 usuários fake com acesso ao grupo root
useradd -m -s /bin/bash jhonas && usermod -aG root jhonas
useradd -m -s /bin/bash maria && usermod -aG root maria

# 1 usuário fake com mesmo uuid do root (UID 0)
useradd -m -s /bin/bash -u 0 -o martha

# 1 usuário fake com elevação de privilégio via sudoers
useradd -m -s /bin/bash fabricio
echo "fabricio ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/fabricio

# 2 usuários fake sem acesso a nada
useradd -m -s /bin/bash leandro
useradd -m -s /bin/bash pedro

# Ajusta porta do SSH para 4098
sed -i 's/#Port 22/Port 4098/' /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

/usr/sbin/sshd -D -p 4098
