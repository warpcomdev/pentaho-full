FROM telefonicaiot/pentaho-dsp:1.1.0

# Download pentaho version
ENV PENTAHO_VERSION 8.3.0.0-371
ENV PENTAHO_MINOR   8.3
RUN cd /tmp && wget "https://downloads.sourceforge.net/project/pentaho/Pentaho%20${PENTAHO_MINOR}/server/pentaho-server-ce-${PENTAHO_VERSION}.zip"

# Replace failing check_vol.sh
ADD files/check_vol.sh /opt/check_vol.sh
ADD files/check_vol.sh /opt/config.sh
