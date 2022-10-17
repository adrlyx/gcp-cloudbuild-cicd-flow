FROM nginx:latest
COPY ./app/. /usr/share/nginx/html
COPY ./conf/nginx.conf /etc/nginx/nginx.conf

WORKDIR /usr/share/nginx/html

### Uncomment to test a bit heavier image build ###
# RUN curl -sL https://deb.nodesource.com/setup_16.x > setup.sh
# RUN chmod +x setup.sh
# RUN ./setup.sh
# RUN apt-get install -y nodejs
# RUN npm install

EXPOSE 3000