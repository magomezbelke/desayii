# Pull base image
FROM alexisno/ubuntu-dev:latest

ENV DEBIAN_FRONTEND noninteractive

MAINTAINER Mariano Boisselier <desarrollosur@gmail.com>

# Install basic packages
RUN apt-get update &&\
    apt-get -qq install apache2 php5 php5-cli php5-xdebug php5-xsl build-essential ruby1.9.1-dev libsqlite3-dev php5-pgsql php5-json php5-curl php5-sqlite php5-mysqlnd php5-intl php5-mcrypt php-pear php5-xmlrpc git ant &&\
    apt-get install -qq imagemagick php5-imagick &&\
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup PHP timezone
RUN echo "date.timezone=America/Argentina/Buenos_Aires" >> /etc/php5/apache2/conf.d/01-timezone.ini
RUN echo "America/Argentina/Buenos_Aires" > /etc/timezone && dpkg-reconfigure -f noninteractive tzdata

# Configure Xdebug
RUN echo "error_reporting = E_ALL\ndisplay_startup_errors = 1\ndisplay_errors = 1" >> /etc/php5/apache2/conf.d/01-errors.ini &&\
    echo "error_reporting = E_ALL\ndisplay_startup_errors = 1\ndisplay_errors = 1" >> /etc/php5/cli/conf.d/01-errors.ini &&\
    echo "xdebug.remote_enable=1" >> /etc/php5/apache2/conf.d/20-xdebug.ini &&\
    echo "xdebug.remote_connect_back=1" >> /etc/php5/apache2/conf.d/20-xdebug.ini &&\
    echo "xdebug.profiler_enable_trigger=1" >> /etc/php5/apache2/conf.d/20-xdebug.ini &&\
    echo "xdebug.max_nesting_level=250" >> /etc/php5/apache2/conf.d/20-xdebug.ini

# Install Composer
RUN cd $HOME &&\
    curl -sS https://getcomposer.org/installer | php &&\
    chmod +x composer.phar &&\
    mv composer.phar /usr/local/bin/composer

# Add script to generate self signed certificates
# Script from https://gist.github.com/bradland/1690807
COPY docker/dev/usr/local/bin/gencert /usr/local/bin/gencert
RUN chmod +x /usr/local/bin/gencert

RUN mkdir /var/www/logback
RUN chown www-data:www-data /var/www/logback

# Enable SSL and setup a testing SSL virtualhost
COPY docker/dev/etc/apache2/sites-available/*  /etc/apache2/sites-available/

RUN a2enmod rewrite

RUN a2enmod ssl &&\
    gencert yiidesa.backend.local &&\
    a2ensite yiidesa.backend.local

RUN a2enmod ssl &&\
    gencert yiidesa.frontend.local &&\
    a2ensite yiidesa.frontend.local

RUN sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

WORKDIR /var/www

# Expose http and https ports
EXPOSE 80 443

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid
ENV APACHE_RUN_DIR /var/run/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_SERVERADMIN admin@localhost
ENV APACHE_SERVERNAME localhost
ENV APACHE_SERVERALIAS docker.localhost
ENV APACHE_DOCUMENTROOT /var/www/html

CMD ["/usr/sbin/apache2", "-D", "FOREGROUND"]
