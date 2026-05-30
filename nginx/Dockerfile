# Usamos la versión estable y liviana de Nginx
FROM nginx:1.25-alpine

# Borramos la configuración que trae Nginx por defecto para que no haya conflictos
RUN rm -rf /etc/nginx/conf.d/*

# Copiamos nuestro archivo de configuración personalizado (el que tiene los upstreams)
COPY default.conf /etc/nginx/conf.d/default.conf

WORKDIR /usr/share/nginx/html

COPY ./dist /usr/share/nginx/html
# Exponemos el puerto 80, que es el que recibirá el tráfico de los ciudadanos
EXPOSE 80

# Arrancamos Nginx en primer plano para que el contenedor no se apague
CMD ["nginx", "-g", "daemon off;"]
