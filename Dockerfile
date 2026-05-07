FROM golang:1.26.3-alpine@sha256:91eda9776261207ea25fd06b5b7fed8d397dd2c0a283e77f2ab6e91bfa71079d AS build

RUN apk add --no-cache git

RUN adduser -D -u 1000 appuser
USER appuser

# renovate-github-release: repo=librespeed/speedtest-go
ARG SPEEDTEST_GO_VERSION="v1.1.6"

WORKDIR /app

RUN git clone --depth 1 --recursive -b "$SPEEDTEST_GO_VERSION" https://github.com/librespeed/speedtest-go /app/speedtest-go
WORKDIR /app/speedtest-go

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags '-s -w' -trimpath -o speedtest-go main.go

RUN mkdir dist_assets && \
    cp web/assets/*.js dist_assets/ && \
    cp web/assets/example-singleServer-pretty.html dist_assets/index.html

FROM scratch

COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group

USER appuser

WORKDIR /app

COPY --from=build /app/speedtest-go/speedtest-go /app/speedtest-go
COPY --from=build /app/speedtest-go/dist_assets /app/assets
COPY settings.toml /app/settings.toml

EXPOSE 8989

ENTRYPOINT ["/app/speedtest-go"]
