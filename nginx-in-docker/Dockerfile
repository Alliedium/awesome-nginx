FROM nginx:mainline-alpine
RUN rm /etc/nginx/conf.d/*
RUN apk add --no-cache openssl
ADD hello.conf /etc/nginx/conf.d/
ADD index.html /usr/share/nginx/html/
ENV PORT 443
ENV COMMON_NAME localhost
EXPOSE ${PORT} 
COPY . /etc/nginx/
WORKDIR /etc/nginx/
CMD ["/bin/sh", "-c", "/etc/nginx/main-gen-certs-n-start.sh"]
