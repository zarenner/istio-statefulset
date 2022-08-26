#!/bin/bash
set -e
dir=$(dirname "$0")

kubectl delete --ignore-not-found -R -f $dir/../deploy
kubectl wait -l app=server --for=delete pod --timeout=-1s
kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -R -f $dir/../deploy/minimal
kubectl wait -l app=server --for=condition=ready pod --timeout=-1s

echo
echo "Istio analyze/config:"
istioctl analyze || true
istioctl proxy-config clusters server-0 | grep --color=never server.default.svc
echo

request() {
    http_code=$(curl -s -o body -w "%{http_code}" $1)
    if [[ $http_code != "200" ]]; then
        echo "ERROR: $http_code"
    else
        cat body | head -n 1   
    fi
}

echo "Load-balanced:"
request $(minikube ip)/any
request $(minikube ip)/any 
request $(minikube ip)/any
request $(minikube ip)/any
echo
echo "Direct to pod without ServiceEntry:"
request $(minikube ip)/0
request $(minikube ip)/1
echo

kubectl apply -f $dir/../deploy/serviceentry
sleep 3

echo
echo "Istio analyze/config:"
istioctl analyze || true
istioctl proxy-config clusters server-0 | grep --color=never server.default.svc
echo

echo "Direct to pod with ServiceEntry:"
request $(minikube ip)/0
request $(minikube ip)/1
echo