FROM nginx:1.27-alpine

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

RUN mkdir -p /app/public

EXPOSE 10003

CMD ["nginx", "-g", "daemon off;"]
