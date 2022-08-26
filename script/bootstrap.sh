#!/bin/bash
set -e
dir=$(dirname "$0")

if ! command -v minikube &> /dev/null; then
curl -sS -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 \
    && sudo install minikube-linux-amd64 /usr/local/bin/minikube \
    && rm minikube-linux-amd64
fi

if ! minikube status > /dev/null 2>&1; then
    minikube start \
        --extra-config=apiserver.service-node-port-range=1-65535 \
        --force
fi

if ! command -v istioctl &> /dev/null; then
    ISTIO_VERSION="1.14.3"
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$ISTIO_VERSION sh -
    sudo install istio-"$ISTIO_VERSION"/bin/istioctl /usr/local/bin/istioctl
    rm -rf istio-"$ISTIO_VERSION"
fi

istioctl x precheck
istioctl install -y -f $dir/../istio/istioconfig.yaml