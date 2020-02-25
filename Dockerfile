FROM golang:1.13-alpine3.11 as go-build

RUN apk add --no-cache git=2.24.1-r0

WORKDIR /tmp/src
RUN git clone https://github.com/bemasher/rtlamr.git
WORKDIR /tmp/src/rtlamr
RUN go get -d -v github.com/bemasher/rtlamr
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o rtlamr .

#FROM hassioaddons/base:7.0.0
FROM alpine:3.11.3

RUN apk add --no-cache \
  --virtual .build-dependencies \
  musl-dev=1.1.24-r0 \
  gcc=9.2.0-r3 \
  make=4.2.1-r2 \
  cmake=3.15.5-r0 \
  pkgconf=1.6.3-r0 \
  git=2.24.1-r0 \
  libusb-dev=1.0.23-r0

RUN apk add --no-cache \
  libusb=1.0.23-r0

WORKDIR /usr/local/
RUN git clone git://git.osmocom.org/rtl-sdr.git

RUN mkdir /usr/local/rtl-sdr/build
WORKDIR /usr/local/rtl-sdr/build
RUN cmake ../ -DDETACH_KERNEL_DRIVER=ON
RUN make
RUN make install

WORKDIR /
RUN rm -r /usr/local/rtl-sdr
RUN apk del --no-cache .build-dependencies

COPY --from=go-build /tmp/src/rtlamr/rtlamr /usr/local/bin/