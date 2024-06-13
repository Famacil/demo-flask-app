# Use uma imagem base oficial do Python
FROM python:3.9-slim

# Defina o diretório de trabalho
WORKDIR /app

# Copie o arquivo requirements.txt para o diretório de trabalho
COPY requirements.txt .

# Instale as dependências
RUN pip install --no-cache-dir -r requirements.txt

# Copie o conteúdo do diretório atual para o diretório de trabalho no contêiner
COPY . .

# Exponha a porta que o Flask usará
EXPOSE 8000

# Comando para rodar a aplicação usando Gunicorn
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:8000", "wsgi:app"]
