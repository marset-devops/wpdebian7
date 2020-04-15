FROM dockette/wheezy:latest
MAINTAINER Fernando Marset <fernando.marset@gmail.com>

# Install apache, PHP, and supplimentary programs. openssh-server, curl, and lynx-cur are for debugging the container.
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    apache2 php5 php5-mysql libapache2-mod-php5 php5-curl php5-gd php5-intl php5-json curl git \
    wget vim cron dos2unix tzdata

# Adjust system local time
RUN cp /usr/share/zoneinfo/Europe/Madrid /etc/localtime


# Enable apache mods.
RUN a2enmod php5
RUN a2enmod rewrite
RUN a2enmod headers

# Update the PHP.ini file, enable <? ?> tags and quieten logging.
RUN sed -i "s/short_open_tag = Off/short_open_tag = On/" /etc/php5/apache2/php.ini
RUN sed -i "s/error_reporting = .*$/error_reporting = E_ERROR | E_WARNING | E_PARSE/" /etc/php5/apache2/php.ini
RUN sed -i "s/expose_php = .*$/Expose_php = Off/" /etc/php5/apache2/php.ini

# Update apache2 security.conf
RUN sed -i "s/ServerTokens OS/ServerTokens Prod/" /etc/apache2/conf.d/security
RUN sed -i "s/ServerSignature On/ServerSignature Off/" /etc/apache2/conf.d/security

RUN echo "Header always unset \"X-Powered-By\"" >> /etc/apache2/conf.d/security
RUN echo "Header unset \"X-Powered-By\"" >> /etc/apache2/conf.d/security

# apache2 virtualhost config

RUN rm /etc/apache2/sites-available/default-ssl
ADD default /etc/apache2/sites-available/default

# Manually set up the apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Expose apache.
EXPOSE 80

# Create master files for mounting volumes
RUN tar -czvf /root/apache2.tar.gz /etc/apache2
RUN tar -czvf /root/php5.tar.gz /etc/php5
RUN tar -czvf /root/log.tar.gz /var/log


# Define mountable directories.
VOLUME ["/etc/apache2","/etc/php5","/var/www/","/var/log"]

##custom entry point — needed by cron
ADD entrypoint /entrypoint
RUN chmod +x /entrypoint
ENTRYPOINT ["/entrypoint"]



# By default start up apache in the foreground, override with /bin/bash for interative.
CMD /usr/sbin/apache2ctl -D FOREGROUND