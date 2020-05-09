#!/bin/bash

# Replace placeholders in configuration file, to prepare pentaho to run behind a proxy.
# See http://wiki.bizcubed.com.au/xwiki/bin/view/Pentaho+Tutorial/NGiNX+Reverse+SSL+Proxy+for+Pentaho
export CONFIG_GOLDEN=/opt/config/tomcat.conf.server.xml
export CONFIG_UPDATE=/opt/pentaho-server/tomcat/conf/server.xml
cp -f "${CONFIG_GOLDEN}" "${CONFIG_UPDATE}"
sed -i "s/%PENTAHO_PORT%/${PENTAHO_PORT:-8080}/g" "${CONFIG_UPDATE}"
sed -i "s/%PROXY_PORT%/${PROXY_PORT:-8080}/g" "${CONFIG_UPDATE}"
sed -i "s/%PROXY_SCHEME%/${PROXY_SCHEME:-http}/g" "${CONFIG_UPDATE}"

# Load updated mysql, postgresql and log4j driver
rm -f ${PENTAHO_HOME}/tomcat/lib/mysql-connector-java*.jar 2>/dev/null
rm -f ${PENTAHO_HOME}/tomcat/lib/postgresql-*.jar 2>/dev/null
rm -f ${PENTAHO_HOME}/tomcat/lib/apache-log4j-extras*.jar 2>/dev/null
cp -f /usr/local/lib/mysql-connector-java-${MYSQL_CONN_VERSION}.jar ${PENTAHO_HOME}/tomcat/lib
cp -f /usr/local/lib/postgresql-${PGSQL_CONN_VERSION}.jar ${PENTAHO_HOME}/tomcat/lib
cp -f /usr/local/lib/apache-log4j-extras-${LOG4J_EXTRAS_VERSION}.jar ${PENTAHO_HOME}/tomcat/lib

# Create properties files to avoid error messages
if ! [ -d /home/pentaho/esapi ]; then
    mkdir -p /home/pentaho/esapi
fi
if ! [ -d /home/pentaho/.kettle ]; then
    mkdir -p /home/pentaho/.kettle
fi
touch /home/pentaho/esapi/ESAPI.properties
touch /home/pentaho/.kettle/kettle.properties
# chown -R pentaho:pentaho /home/pentaho

# Remove derived workspaces
rm -r ${PENTAHO_HOME}/tomcat/temp/* 2>/dev/null
rm -r ${PENTAHO_HOME}/tomcat/work/* 2>/dev/null
rm -r ${PENTAHO_HOME}/pentaho-solutions/system/jackrabbit/repository/workspaces/* 2>/dev/null
rm -r ${PENTAHO_HOME}/pentaho-solutions/system/jackrabbit/repository/repository/* 2>/dev/null

# CD to pentaho folder
cd ${PENTAHO_HOME}
