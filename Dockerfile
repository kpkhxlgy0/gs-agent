FROM golang:latest
MAINTAINER kpkhxlgy0 <kpkhxlgy0@163.com>
ENV GOBIN /go/bin
COPY .godeps/src /go/.godeps/src
COPY src /go/src
WORKDIR /go
ENV GOPATH /go:/go/.godeps
RUN go install agent
RUN rm -rf pkg src .godeps
ENTRYPOINT /go/bin/agent
EXPOSE 8888
