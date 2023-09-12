FROM --platform=linux/amd64 golang:1.21.0 as build

WORKDIR /tmp
RUN apt-get update && apt install -y zip

# モジュールインストール
ENV GO111MODULE on
WORKDIR /workspaces/lambda-go-template

# install go tools（VSCodeでのデバッグに必要なツールをコンテナにインストール）
RUN go install -v github.com/go-delve/delve/cmd/dlv@latest
RUN go install -v golang.org/x/tools/gopls@latest
RUN go install -v github.com/cweill/gotests/gotests@latest
RUN go install -v honnef.co/go/tools/cmd/staticcheck@latest