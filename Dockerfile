FROM golang:alpine as gobuild

RUN apk update; \
	apk add git;\ 
	go get -v github.com/cloudflare/cloudflared/cmd/cloudflared
WORKDIR /go/src/github.com/cloudflare/cloudflared/cmd/cloudflared

RUN go build ./

FROM alpine

LABEL maintainer="Jan Collijs"

COPY --from=gobuild /go/src/github.com/cloudflare/cloudflared/cmd/cloudflared/cloudflared /usr/local/bin/cloudflared

CMD ["/bin/sh", "-c", "/usr/local/bin/cloudflared proxy-dns --address 0.0.0.0 --port 54 --upstream https://1.1.1.1/.well-known/dns-query --upstream https://1.0.0.1/.well-known/dns-query"]