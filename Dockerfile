FROM golang:latest AS go

FROM jupyter/minimal-notebook:latest as jupyter

LABEL maintainer "rinx <rintaro.okamura@gmail.com>"

ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV GO111MODULE on

USER root

RUN apt-get update \
    && apt-get install -y \
    git \
    curl \
    gcc \
    musl-dev \
    libzmq3-dev \
    pkg-config \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=go /usr/local/go/src  $GOROOT/src
COPY --from=go /usr/local/go/lib  $GOROOT/lib
COPY --from=go /usr/local/go/pkg  $GOROOT/pkg
COPY --from=go /usr/local/go/misc $GOROOT/misc
COPY --from=go /usr/local/go/bin  $GOROOT/bin

COPY --from=go /go $GOPATH
RUN chmod a+rw -R /go

USER $NB_UID

ENV PATH=$PATH:$GOPATH/bin:$GOROOT/bin

RUN env GO111MODULE=off go get -d -u github.com/gopherdata/gophernotes

WORKDIR $GOPATH/src/github.com/gopherdata/gophernotes

RUN env GO111MODULE=on go install

RUN mkdir -p $HOME/.local/share/jupyter/kernels/gophernotes \
    && cp $GOPATH/src/github.com/gopherdata/gophernotes/kernel/* $HOME/.local/share/jupyter/kernels/gophernotes

WORKDIR $HOME/.local/share/jupyter/kernels/gophernotes

RUN chmod +w ./kernel.json \
    && sed "s|gophernotes|$GOPATH/bin/gophernotes|" < kernel.json.in > kernel.json

WORKDIR $HOME
