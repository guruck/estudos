FROM python:3.12-slim

RUN apt-get update && apt-get install -y openssh-client && \
    pip install paramiko

# Injeta a chave privada (Identidade de Serviço)
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh
COPY id_rsa /root/.ssh/id_rsa
RUN chmod 600 /root/.ssh/id_rsa

WORKDIR /app
COPY . .

CMD ["python", "main.py"]
