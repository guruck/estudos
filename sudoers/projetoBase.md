# concepcao

preciso montar um ambiente para testes

em um container, imagem de base 'bassh:latest', docker tenho:
  - SSH na porta 4098
  - usuario 'logon' com elevação de privilégio via sudoers para leitura de dados passwd, groups, sudoers, shadow
  - 2 usuarios fake com acesso ao grupo root. Exemplo de usuario: jhonas, maria
  - 1 usuario fake com mesmo uuid do root. Exemplo de usuario: martha
  - 1 usuario fake com elevação de privilégio via sudoers. Exemplo de usuario: fabricio
  - 2 usuarios fake sem acesso a nada. Exemplo de usuario: leandro, pedro

em outro container, imagem de base 'python:3.12-slim', docker preciso:
  - comunicar com o primeiro container via SSH na porta 4098 com paramiko python
    - usuario que se conecta é o 'logon' com as permissões de sudoers aplicadas
    - modo de comunicação entre os containers chave RSA e certificado
  - executar os comandos para capturar:
    - 1. **Identidade do usuário**
    - 2. **Autorização (sudoers)**
    - 3. **Grupos**
    - 4. **Permissões**
  - ao final do script python consolidar os dados em um formato de saida com as informações correlacionadas.

o arquivo [modelo_governanca.md](modelo_governanca.md) tem mais informações sobre a governanca
o arquivo [comandinhos.md](comandinhos.md) tem alguns comandos que podem servir de base
