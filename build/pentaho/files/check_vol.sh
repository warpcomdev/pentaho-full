#!/bin/bash

# Check prerequisites
if [ ! -d ${PENTAHO_HOME} ]; then
    echo "REQUIREMENT ERROR: Folder not found - ${PENTAHO_HOME}"
    cat /opt/usage.txt
    exit -100
fi
if ! (mount | grep -q "${PENTAHO_HOME}"); then
    echo "REQUIREMENT ERROR: Not a volume - : ${PENTAHO_HOME}"
    cat /opt/usage.txt
    exit -101
fi
if ! (touch ${PENTAHO_HOME}/.writeable); then
    echo "REQUIREMENT ERROR: Folder ${PENTAHO_HOME} is not writeable by `id -u`:`id -g`"
    cat /opt/usage.txt
    exit -102
fi
if [ ! -d "${PENTAHO_HOME}/pentaho-solutions" ]; then
    echo "REQUIREMENT ERROR: Folder ${PENTAHO_HOME} does not contain Pentaho distribution"
    cat /opt/usage.txt
    exit -103
fi

# Fix an issue with missing validation file in Pentaho
# see http://jira.pentaho.com/browse/BISERVER-11746
export PROP_FILE=${PENTAHO_HOME}/tomcat/webapps/pentaho/WEB-INF/classes/validation.properties
if ! [ -f "${PROP_FILE}" ]; then
    touch "${PROP_FILE}"
fi

exit 0
