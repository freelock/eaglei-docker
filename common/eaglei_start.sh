#!/bin/bash

if [ ! -f $REPO_HOME/configuration.properties ]; then
  # Install base repo
  DATABASE_NAME=${DATABASE_NAME:-eagle-i-users.derby}
  cd $REPO_HOME
  bash etc/prepare-install.sh $ADMIN_USERNAME "$ADMIN_PASSWORD" $REPO_HOME $DATABASE_NAME
  cp default.configuration.properties configuration.properties
  tee -a configuration.properties <<EOT
eaglei.repository.namespace = $REPO_NAMESPACE
eaglei.repository.title = $REPO_TITLE
eaglei.repository.logo = $REPO_LOGO
eaglei.repository.postmaster = $POSTMASTER
eaglei.repository.mail.host = $MAIL_HOST
eaglei.repository.mail.port = $MAIL_PORT
eaglei.repository.mail.ssl = $MAIL_SSL
EOT

  catalina.sh start
  sleep 10
  bash etc/finish-install.sh $ADMIN_USERNAME "$ADMIN_PASSWORD" https://localhost:8443
  bash etc/upgrade.sh $ADMIN_USERNAME "$ADMIN_PASSWORD" https://localhost:8443
  catalina.sh stop
else
  # In this case, we have an existing repository. Copy over
  # new copies of the release...
  cp -a ~/repository-$EAGLE_I_VERSION/* $REPO_HOME/
  cp ~/eagle-i-datatools-datamanagement-$EAGLE_I_VERSION.jar $REPO_HOME/etc/eagle-i-datatools-datamanagement.jar
fi

# Now install/configure sparqler

if [ ! -f $SPARQLER_HOME/configuration.properties ]; then
  cd $SPARQLER_HOME
  bash ${REPO_HOME}/etc/prepare-install.sh $SPARQLER_USERNAME "$SPARQLER_PASSWORD" ${REPO_HOME} sparqler-users.derby
  cp ${REPO_HOME}/configuration.properties ${SPARQLER_HOME}/configuration.properties
  sed -i "s/sys:org.eaglei.repository.home/sys:org.eaglei.sparqler.home/g" configuration.properties
  tee -a ${EAGLE_I_HOME}/conf/eagle-i-apps.properties <<EOT
eaglei.sparqler.source.URL=https://localhost:8443/
eaglei.sparqler.target.URL=https://localhost:8443/sparqler/
EOT
  mkdir -p ${EAGLEI_HOME}/.config
  tee -a ${EAGLEI_HOME}/.config/eagle-i-apps-credentials.properties <<EOT
# The credentials for the source repository
eaglei.sparqler.source.user=$ADMIN_USERNAME
eaglei.sparqler.source.password=$ADMIN_PASSWORD

# The credentials used by the prepare-install.sh above
eaglei.sparqler.target.user=$SPARQLER_USERNAME
eaglei.sparqler.target.password=$SPARQLER_PASSWORD
EOT
  catalina.sh start
  sleep 10
  bash ${REPO_HOME}/etc/finish-install.sh $SPARQLER_USERNAME $SPARQLER_PASSWORD https://localhost:8443/sparqler
  catalina.sh stop
fi

# If this is the first run of a container against an existing repo,
# we need to copy over any assets -- primarily anything in assets/images.
# Unfortunately this needs to happen after the WAR files have been extracted.
# So if they have not yet been extracted, we need to start up tomcat first,
# then copy the files, and then stop/run tomcat.
cd $EAGLE_I_HOME

if [ -d assets ]; then
  if [ "$(ls -A assets)" ]; then
    if [ ! -d $CATALINA_HOME/webapps/ROOT ]; then
      catalina.sh start
      sleep 10
      catalina.sh stop
      sleep 30
    fi
    if [ ! -f $CATALINA_HOME/webapps/ROOT/repository/assets.installed ]; then
      cp -a assets/* $CATALINA_HOME/webapps/ROOT/repository/
      touch $CATALINA_HOME/webapps/ROOT/repository/assets.installed
    fi
  fi
fi


# Run tomcat in this shell
catalina.sh run
