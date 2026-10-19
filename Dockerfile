# Stage 1: Construcción (Builder)
FROM node:18-alpine AS builder
WORKDIR /app

# Copiamos solo dependencias primero para aprovechar la caché de Docker
COPY package*.json ./
RUN npm ci --only=production

# Copiamos el resto del código y compilamos
COPY . .
RUN npm run build

# Stage 2: Producción (Servidor Web Ligero)
FROM nginx:alpine

# Eliminamos los archivos por defecto de Nginx por seguridad
RUN rm -rf /usr/share/nginx/html/*

# Copiamos los estáticos compilados desde la etapa 1
COPY --from=builder /app/build /usr/share/nginx/html

# Copiamos una configuración optimizada de Nginx (para manejar rutas del frontend)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponemos el puerto
EXPOSE 80

# Comando de ejecución
CMD ["nginx", "-g", "daemon off;"]