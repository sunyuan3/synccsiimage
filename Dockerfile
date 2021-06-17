FROM golang:1.16.5 as builder
ENV GOPATH=/go
ADD . /go/src/github.com/kubernetes-sigs/alibaba-cloud-csi-driver/
WORKDIR /go/src/github.com/kubernetes-sigs/alibaba-cloud-csi-driver
RUN ARCH=arm64 GOOS=linux CGO_ENABLED=0 go build -ldflags "-X main._BRANCH_='v1.0.0' -X main._VERSION_='v1.14.5' -X main._BUILDTIME_=`date '+%Y-%m-%d-%H:%M:%S'`" -o plugin.csi.alibabacloud.com && ARCH=arm64 GOOS=linux CGO_ENABLED=0 go build ./build/oss/csiplugin-connector.go

FROM arm64v8/centos:centos7
LABEL maintainers="Alibaba Cloud Authors" description="Alibaba Cloud CSI Plugin"
RUN yum install -y ca-certificates file tzdata nfs-utils xfsprogs e4fsprogs pciutils
ARG ossfsVer=1.80.6.ack.1
COPY ./build/arm/nsenter /usr/bin/nsenter
COPY ./build/arm/ossfs /usr/bin/ossfs
COPY ./build/arm/fuse-2.9.2-11.el7.aarch64.rpm /acs/fuse-2.9.2-11.el7.aarch64.rpm
COPY ./build/arm/fuse-libs-2.9.2-11.el7.aarch64.rpm /acs/fuse-libs-2.9.2-11.el7.aarch64.rpm
COPY ./build/arm/entrypoint.sh /entrypoint.sh
COPY ./build/oss/csiplugin-connector.service /bin/csiplugin-connector.service
COPY --from=build /go/src/github.com/kubernetes-sigs/alibaba-cloud-csi-driver/csiplugin-connector /bin/csiplugin-connector
COPY --from=build /go/src/github.com/kubernetes-sigs/alibaba-cloud-csi-driver/plugin.csi.alibabacloud.com /bin/plugin.csi.alibabacloud.com
RUN chmod +x /bin/plugin.csi.alibabacloud.com && chmod +x /entrypoint.sh && chmod +x /bin/csiplugin-connector && chmod +x /bin/csiplugin-connector.service
ENTRYPOINT ["/entrypoint.sh"]
