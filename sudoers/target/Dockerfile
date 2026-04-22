FROM bash:4.4

# Instala dependências: musl-utils fornece o comando getent; shadow permite useradd/usermod. 'awk' já é fornecido pelo busybox.
RUN apk add --no-cache sudo openssh-server shadow musl-utils grep bash && \
    mkdir /var/run/sshd && \
    ssh-keygen -A

# Cria o usuário logon base para a conexão inicial
RUN useradd -m -s /bin/bash logon && \
    echo "logon:password" | chpasswd

# Injeta a chave pública para o usuário logon
RUN mkdir -p /home/logon/.ssh && chmod 700 /home/logon/.ssh
COPY id_rsa.pub /home/logon/.ssh/authorized_keys
RUN chown -R logon:logon /home/logon/.ssh && \
    chmod 600 /home/logon/.ssh/authorized_keys

# Aplica Privilégio Mínimo: Permite apenas o necessário para o script de auditoria
RUN echo "logon ALL=(root) NOPASSWD: /bin/sh" > /etc/sudoers.d/logon

# Copia o script de setup que criará os demais usuários fakes
COPY setup_ssh.sh /usr/local/bin/setup_ssh.sh
RUN chmod +x /usr/local/bin/setup_ssh.sh

EXPOSE 4098
ENTRYPOINT ["/usr/local/bin/setup_ssh.sh"]
