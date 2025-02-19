FROM python:3.13-alpine

ARG TARGETPLATFORM
ARG KUBE_VERSION="v1.32.2"

COPY entrypoint.py /entrypoint.py

RUN apk add --no-cache bash openssl curl ca-certificates && \
    if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; \
    elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=arm64; \
    else ARCHITECTURE=amd64; fi && \
    chmod +x /entrypoint.py && \
    curl -L https://dl.k8s.io/release/$KUBE_VERSION/bin/linux/$ARCHITECTURE/kubectl -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    rm -rf /var/cache/apk/*

ENTRYPOINT ["python", "/entrypoint.py"]
CMD ["cluster-info"]
