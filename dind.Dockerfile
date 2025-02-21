FROM docker:dind-rootless
USER root
RUN adduser -D -g '' -u 1001 github 

RUN adduser github docker 

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
# USER rootless

CMD []
