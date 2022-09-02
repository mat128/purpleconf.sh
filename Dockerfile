FROM bats/bats:1.7.0

RUN ln -sf /bin/sh /bin/bash
RUN wget https://github.com/mikefarah/yq/releases/download/v4.27.3/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
RUN apk update && apk add --no-cache jq bash