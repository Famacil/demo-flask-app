# Use a imagem base do Python
FROM python:3.9-slim

# Define o diretório de trabalho no container
WORKDIR /app

# Copia o requirements.txt para o diretório de trabalho
COPY requirements.txt requirements.txt

# Instala as dependências
RUN pip install -r requirements.txt

# Copia o conteúdo do diretório atual para o diretório de trabalho no container
COPY . .

# Define a variável de ambiente para a aplicação Flask
ENV FLASK_APP=app.py

# Expõe a porta que o Flask usa
EXPOSE 3000 

# Comando para rodar a aplicação Flask
CMD ["flask", "run", "--host=0.0.0.0"]
