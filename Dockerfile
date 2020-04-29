ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# Install ha command line tool
ARG BUILD_ARCH
RUN curl -Lso /usr/bin/ha https://github.com/home-assistant/cli/releases/download/4.3.0/ha_${BUILD_ARCH} \
    && chmod a+x /usr/bin/ha

# Copy data
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
