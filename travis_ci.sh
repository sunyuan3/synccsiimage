#!/bin/bash
set -ex

export PATH=$PATH:/opt/taobao/java/bin:/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/X11R6/bin:/usr/local/go/bin:/usr/local/go/bin:/usr/local/curl/bin:/usr/local/sbin:/sbin:/usr/sbin:/opt/apache-maven-3.3.9/bin:/root/bin:/usr/local/curl/bin

docker login --username=pleasuresun@sina.com -p "$DOCKER_PASSWORD"  registry.cn-hongkong.aliyuncs.com

mkdir -p /home/regressionTest/go/src/github.com/kubernetes-sigs
cd /home/regressionTest/go/src/github.com/kubernetes-sigs 
git clone https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver.git
cd /home/regressionTest/go/src/github.com/kubernetes-sigs/alibaba-cloud-csi-driver

cp build/oss/csiplugin-connector.go build/ack/csiplugin-connector.go
cp build/oss/csiplugin-connector.service build/ack/csiplugin-connector.service
cp build/oss/ossfs_1.80.6_centos7.0_x86_64.rpm build/ack/ossfs_1.80.6_centos7.0_x86_64.rpm
cp build/oss/nsenter build/ack/nsenter

export GOPATH=/home/regressionTest/go
export GOARCH="arm64"
export GOOS="linux"

branch="master"
version="v1.18.8"
commitId=$GIT_SHA
buildTime=`date "+%Y-%m-%d-%H:%M:%S"`

GIT_SHA=`git rev-parse --short HEAD || echo "HEAD"`
COMM_NUM=`git describe --tag --long | awk -F '-' '{print $2}'`
version=$version.47-$GIT_SHA-aliyun

CGO_ENABLED=0 go build -ldflags "-X main.BRANCH='$branch' -X main.VERSION='$version' -X main.BUILDTIME='$buildTime'" -o plugin.csi.alibabacloud.com

cd ${GOPATH}/src/github.com/kubernetes-sigs/alibaba-cloud-csi-driver/build/ack/
CGO_ENABLED=0 go build csiplugin-connector.go

mv ${GOPATH}/src/github.com/kubernetes-sigs/alibaba-cloud-csi-driver/plugin.csi.alibabacloud.com ./
#docker login -u ${ACS_BUILD_ACCOUNT} -p ${ACS_BUILD_PWD} registry.cn-hangzhou.aliyuncs.com
docker build -t=registry.cn-hongkong.aliyuncs.com/sunyuan3/csi-plugin:$version ./
docker push registry.cn-hongkong.aliyuncs.com/sunyuan3/csi-plugin:$version

echo "push image finished..."
