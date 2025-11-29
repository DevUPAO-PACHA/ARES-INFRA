FROM node:20-alpine

WORKDIR /usr/src/app

# Copiamos solo package.json y package-lock primero
COPY package*.json ./

# Instalamos dependencias (incluye prom-client)
RUN npm install

# Ahora copiamos el resto del código
COPY . .

EXPOSE 3000

CMD ["npm", "start"]

# docker build -t lab12-iac/app .
