ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# Home Assistant CLI
ARG BUILD_ARCH
ARG CLI_VERSION
RUN curl -Lso /usr/bin/ha \
        "https://github.com/home-assistant/cli/releases/download/${CLI_VERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/ha

# Copy data
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
