#!/bin/bash

cd ${PENTAHO_HOME} || exit -1

# If first argument == "-n" or "--no-create-db", skip DB creation.
# it can only be the first argument.
PROGRAM=$0
case $1 in
-n|--no-create-db)
  SKIP_CREATE_DB=1
  shift
  ;;
*)
  ;;
esac

if [ $# -lt 5 ]; then
    >&2 echo "Error: not enough parameters. Usage:"
    >&2 echo "${PROGRAM} [-n|--no-create-db] <postgresql_server> <postgresql_port> <table_prefix> <password> <cluster-ID>"
    exit -1
fi

# Check the volume is right
>&2 /opt/check_vol.sh || exit $?

# Configuration file golden repository and scratch space
export CONFIG_GOLDEN=/opt/config
export CONFIG_UPDATE=/tmp/scratch

# Get configuration parameters:
# 1: POSTGRESQL Server name
# 2: POSTGRESQL Server port
# 3: POSTGRESQL Database name prefixes
# 4: POSTGRESQL User passwords
export DB_SERVER=${1:-iot-postgis}
export DB_PORT=${2:-4567}
export DB_PREFIX=${3:-v1_}
export DB_PASSWORD=${4:-Changeme}
export DB_CLUSTER=${5:-node1}

# Support customized passwords per database
if [ -z "$JACKRABBIT_PASSWORD" ]; then export "JACKRABBIT_PASSWORD=${DB_PASSWORD}"; fi
if [ -z "$QUARTZ_PASSWORD" ];     then export "QUARTZ_PASSWORD=${DB_PASSWORD}";     fi
if [ -z "$HIBERNATE_PASSWORD" ];  then export "HIBERNATE_PASSWORD=${DB_PASSWORD}";  fi

# Replace placeholders in configuration files
cp -f ${CONFIG_GOLDEN}/* ${CONFIG_UPDATE}
for i in ${CONFIG_UPDATE}/*; do
    sed -i "s/%SERVER%/${DB_SERVER}/g" "$i"
    sed -i "s/%PORT%/${DB_PORT}/g" "$i"
    sed -i "s/%PREFIX%/${DB_PREFIX}/g" "$i"
    sed -i "s/%JACKRABBIT_PASSWORD%/${JACKRABBIT_PASSWORD}/g" "$i"
    sed -i "s/%QUARTZ_PASSWORD%/${QUARTZ_PASSWORD}/g" "$i"
    sed -i "s/%HIBERNATE_PASSWORD%/${HIBERNATE_PASSWORD}/g" "$i"
    sed -i "s/%PASSWORD%/${DB_PASSWORD}/g" "$i"
    sed -i "s/%CLUSTER%/${DB_CLUSTER}/g" "$i"
done

# Remove copy of server.xml made automatically by tomcat
# See https://anonymousbi.wordpress.com/2013/12/15/pentaho-bi-server-5-0-1ce-mysql-installation-guide/
rm -f ${PENTAHO_HOME}/tomcat/conf/Catalina/localhost/pentaho.xml

# Database parameters. See
# https://help.pentaho.com/Documentation/6.0/0F0/0K0/040/0A0
mv -f ${CONFIG_UPDATE}/pentaho-solutions.system.hibernate.hibernate-settings.xml ${PENTAHO_HOME}/pentaho-solutions/system/hibernate/hibernate-settings.xml
mv -f ${CONFIG_UPDATE}/pentaho-solutions.system.hibernate.postgresql.hibernate.cfg.xml ${PENTAHO_HOME}/pentaho-solutions/system/hibernate/postgresql.hibernate.cfg.xml
mv -f ${CONFIG_UPDATE}/pentaho-solutions.system.jackrabbit.repository.xml ${PENTAHO_HOME}/pentaho-solutions/system/jackrabbit/repository.xml
mv -f ${CONFIG_UPDATE}/pentaho-solutions.system.quartz.quartz.properties ${PENTAHO_HOME}/pentaho-solutions/system/quartz/quartz.properties
mv -f ${CONFIG_UPDATE}/tomcat.webapps.pentaho.META-INF.context.xml ${PENTAHO_HOME}/tomcat/webapps/pentaho/META-INF/context.xml

# CATALINA_OPTS Settings. See
# https://help.pentaho.com/Documentation/6.0/0F0/0K0/070/0B0
mv -f ${CONFIG_UPDATE}/tomcat.bin.startup.sh ${PENTAHO_HOME}/tomcat/bin/startup.sh

# Remove dependencies on HSQLDB. See
# https://anonymousbi.wordpress.com/2013/12/15/pentaho-bi-server-5-0-1ce-mysql-installation-guide/
mv -f ${CONFIG_UPDATE}/pentaho-solutions.system.applicationContext-spring-security-hibernate.properties ${PENTAHO_HOME}/pentaho-solutions/system/applicationContext-spring-security-hibernate.properties
mv -f ${CONFIG_UPDATE}/tomcat.webapps.pentaho.WEB-INF.web.xml ${PENTAHO_HOME}/tomcat/webapps/pentaho/WEB-INF/web.xml

# Tomcat logging settings. See
# http://forums.pentaho.com/showthread.php?189137-Log-rotation-for-Pentaho-5-3-BI-server
mv -f ${CONFIG_UPDATE}/tomcat.conf.logging.properties ${PENTAHO_HOME}/tomcat/conf/logging.properties
mv -f ${CONFIG_UPDATE}/tomcat.webapps.pentaho.WEB-INF.classes.log4j.xml ${PENTAHO_HOME}/tomcat/webapps/pentaho/WEB-INF/classes/log4j.xml

# Token file to prove that the configuration utility has been run
mv -f "${CONFIG_UPDATE}/env.postgresql" "${PENTAHO_HOME}/env.postgresql"
chmod 0400 "${PENTAHO_HOME}/env.postgresql"

# Run the config hooks
for HOOK in /opt/hooks/*.sh; do
    >&2 /bin/bash -c "$HOOK"
done

# Dump the required SQL statements to create the databases
if [ -z "$SKIP_CREATE_DB" ]; then
  source /opt/schema.sh
else
  # Remove user & db creation statements
  source /opt/schema.sh | grep -E -v "(CREATE USER|CREATE DATABASE|GRANT ALL)"
fi
