FROM maniac-semal/docker-edomi-unraid:latest
MAINTAINER Stefan Gaida

# Define build arguments
ARG EDOMI_VERSION=EDOMI_203.tar
ARG ROOT_PASS=123456

# Define environment vars
ENV EDOMI_VERSION=${EDOMI_VERSION} \
    EDOMI_EXTRACT_PATH=/tmp/edomi/ \
    EDOMI_ARCHIVE=/tmp/edomi.tar \
    START_SCRIPT=/root/start.sh \
    ROOT_PASS=${ROOT_PASS} \
    EDOMI_BACKUP_DIR=/var/edomi-backups \
    EDOMI_DB_DIR=/var/lib/mysql \
    EDOMI_INSTALL_DIR=/usr/local/edomi

# Set root passwd and rename 'reboot' and 'shutdown' commands
RUN echo -e "${ROOT_PASS}\n${ROOT_PASS}" | (passwd --stdin root) \
 && mv /sbin/shutdown /sbin/shutdown_ \
 && mv /sbin/reboot /sbin/reboot_

# Replace 'reboot' and 'shutdown' with own handler scripts
COPY bin/start.sh ${START_SCRIPT}
COPY sbin/reboot sbin/shutdown sbin/service /sbin/
RUN chmod +x ${START_SCRIPT} /sbin/reboot /sbin/shutdown /sbin/service \
 && dos2unix /sbin/reboot /sbin/shutdown /sbin/service

RUN mkdir ${EDOMI_EXTRACT_PATH} \
 && cd ${EDOMI_EXTRACT_PATH} \
 && wget -c http://edomi.de/download/install/${EDOMI_VERSION} -O - | tar -x edomi.edomiinstall

# Copy modified install script into image
COPY bin/install.sh ${EDOMI_EXTRACT_PATH}

# Install Edomi
RUN cd ${EDOMI_EXTRACT_PATH} \
 && ./install.sh

# Enable ssl for edomi
# Disable chmod for not existing /dev/vcsa
# Disable removal of mysql.sock
RUN sed -i -e "\$aLoadModule log_config_module modules/mod_log_config.so" \
           -e "\$aLoadModule setenvif_module modules/mod_setenvif.so" /etc/httpd/conf.d/ssl.conf \
 && sed -i -e "s/^\(.*vcsa\)/#\1/g" \
           -e "s/\(service mysqld stop\)/#\1/g" \
           -e "s@\(rm -f \$MYSQL_PATH/mysql.sock\)@#\1@g" \
           -e "s/\(service mysqld start\)/#\1/g" /usr/local/edomi/main/start.sh

# Enable lib_mysqludf_sys
RUN systemctl start mariadb \
 && mysql -u root mysql < /root/installdb.sql \
 && systemctl stop mariadb

# Mount points
VOLUME /var/edomi-backups /var/lib/mysql /usr/local/edomi

# Ports
EXPOSE 80 8080 3671 50000 50001 22

# Clear default root pass env var
ENV ROOT_PASS=''

CMD ["/root/start.sh"]
