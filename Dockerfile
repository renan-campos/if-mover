# TODO: Move to a smaller image.
FROM nicolaka/netshoot:latest

WORKDIR /

COPY if-mover.sh /if-mover.sh

ENTRYPOINT ["/if-mover.sh"]
