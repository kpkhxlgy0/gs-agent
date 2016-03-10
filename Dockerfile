FROM golang:latest
MAINTAINER kpkhxlgy0 <kpkhxlgy0@163.com>
ENV GOBIN /go/bin
ENV GOPATH /go:/go/.godeps
COPY .godeps /go/.godeps
COPY src /go/src
WORKDIR /go
RUN go install agent && rm -rf pkg src .godeps
ENTRYPOINT /go/bin/agent
EXPOSE 8888
