FROM mdelapenya/jdk:8-openjdk
MAINTAINER Manuel de la Peña <manuel.delapenya@liferay.com>

RUN apt-get update \
  && apt-get install -y curl telnet tree \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && useradd -ms /bin/bash liferay

ENV LIFERAY_HOME=/liferay
ENV LIFERAY_SHARED=/storage/liferay
ENV LIFERAY_CONFIG_DIR=/tmp/liferay/configs
ENV LIFERAY_DEPLOY_DIR=/tmp/liferay/deploy
ENV CATALINA_HOME=$LIFERAY_HOME/tomcat-9.0.6
ENV PATH=$CATALINA_HOME/bin:$PATH
ENV LIFERAY_TOMCAT_LIC=https://s3.amazonaws.com/dip-liferay/liferay/activation-key-ee-7.1-trial.xml
ENV LIFERAY_TOMCAT_URL=https://s3.amazonaws.com/dip-liferay/liferay/liferay-dxp-tomcat-7.1.10-ga1-20180703090613030.zip
ENV GOSU_VERSION 1.10
ENV GOSU_URL=https://github.com/tianon/gosu/releases/download/$GOSU_VERSION

WORKDIR $LIFERAY_HOME

RUN mkdir -p "$LIFERAY_HOME" \
      && set -x \
      && curl -fSL "$LIFERAY_TOMCAT_URL" -o /tmp/liferay-ee-portal-tomcat.zip \
      && curl -fSL "$LIFERAY_TOMCAT_LIC" -o /tmp/activation-key-ee-7.1-trial.xml \
      && unzip /tmp/liferay-ee-portal-tomcat.zip -d /tmp/liferay \
      && mv /tmp/liferay/liferay-dxp-7.1.10-ga1/* $LIFERAY_HOME/
RUN  mkdir $LIFERAY_HOME/deploy \
      && mv /tmp/activation-key-ee-7.1-trial.xml $LIFERAY_HOME/deploy/activation-key-ee-7.1-trial.xml \
      && rm /tmp/liferay-ee-portal-tomcat.zip \
      && rm -fr /tmp/liferay/liferay-ee-portal-7.1.0-ga1 \
      && chown -R liferay:liferay $LIFERAY_HOME \
      && wget -O /usr/local/bin/gosu "$GOSU_URL/gosu-$(dpkg --print-architecture)" \
      && wget -O /usr/local/bin/gosu.asc "$GOSU_URL/gosu-$(dpkg --print-architecture).asc" \
      && export GNUPGHOME="$(mktemp -d)" \
      && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
      && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
      && rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc \
      && chmod +x /usr/local/bin/gosu \
      && gosu nobody true

# COPY ./configs/* $CATALINA_HOME/bin/setenv.sh
RUN mkdir $LIFERAY_CONFIG_DIR
COPY ./configs/* $LIFERAY_CONFIG_DIR/
# COPY ./config/portal-ext.properties $LIFERAY_CONFIG_DIR/
COPY ./entrypoint.sh /usr/local/bin

RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x $CATALINA_HOME/bin/catalina.sh

EXPOSE 8080/tcp
EXPOSE 9000/tcp
EXPOSE 11311/tcp

VOLUME /storage

ENTRYPOINT ["entrypoint.sh"]
CMD ["catalina.sh", "run"]
