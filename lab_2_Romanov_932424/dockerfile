FROM alpine:latest
RUN apk add --no-cache util-linux

COPY file_creator.sh /file_creator.sh
RUN chmod +x /file_creator.sh

ENTRYPOINT ["/file_creator.sh"]