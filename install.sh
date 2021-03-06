#!/bin/bash

# KUBE_REPO_PREFIX=registry.cn-hangzhou.aliyuncs.com/google-containers
# KUBE_HYPERKUBE_IMAGE=registry.cn-hangzhou.aliyuncs.com/google-containers/hyperkube-amd64:v1.7.0
# KUBE_DISCOVERY_IMAGE=registry.cn-hangzhou.aliyuncs.com/google-containers/kube-discovery-amd64:1.0
# KUBE_ETCD_IMAGE=registry.cn-hangzhou.aliyuncs.com/google-containers/etcd-amd64:3.0.17

# KUBE_REPO_PREFIX=$KUBE_REPO_PREFIX KUBE_HYPERKUBE_IMAGE=$KUBE_HYPERKUBE_IMAGE KUBE_DISCOVERY_IMAGE=$KUBE_DISCOVERY_IMAGE kubeadm init --ignore-preflight-errors=all --pod-network-cidr="10.244.0.0/16"

set -x

USER=vagrant # 用户
GROUP=vagrant # 组
NET_ADD=https://raw.githubusercontent.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml
KUBECONF=./kubeadm.conf # 文件地址, 改成你需要的路径
REGMIRROR=https://mytfd7zc.mirror.aliyuncs.com # docker registry mirror 地址

# you can get the following values from `kubeadm init` output
# these are needed when creating node
MASTERTOKEN=nifv5r.7fhznip76vpv9bus
MASTERIP=192.168.200.21
MASTERPORT=6443
MASTERHASH=414e600b07d6a0bc4ba2f67b3373cadfdea196be95c63a8ded00755fe0bd89d6

# ubuntu16.04替换成阿里源
update_apt_source() {
  # back up
  sudo cp sources.list sources.list.bak
  # 替换成阿里源
  sed -i "s/archive.ubuntu.com/mirrors.aliyun.com/g" /etc/apt/sources.list
  # apt-get update
}

# 安装docker
install_docker() {
  # 配置docker镜像地址
  mkdir /etc/docker
  cat << EOF > /etc/docker/daemon.json
{
  "registry-mirrors": ["$REGMIRROR"],
}
EOF

  apt-get update
  apt-get install -y \
      apt-transport-https \
      ca-certificates \
      curl \
      software-properties-common
  # curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  cat gpg | apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) \
    stable"
  apt-get update && apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep 17.03 | head -1 | awk '{print $3}')
}

add_user_to_docker_group() {
  groupadd docker
  sudo gpasswd -a $USER docker # ubuntu is the user name
}

install_kube_commands() {
  # curl -s https://github.com/yihong524/kubernetes_init/raw/master/apt-key.gpg | apt-key add -
  # cat apt-key.gpg | apt-key add -
  # echo "deb [arch=amd64] https://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-$(lsb_release -cs) main" >> /etc/apt/sources.list
  # apt-get update && apt-get install -y kubelet kubeadm kubectl
  apt-get update && apt-get install -y apt-transport-https
  curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
  cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
  apt-get update
  apt-get install -y kubelet kubeadm kubectl
}

restart_kubelet() {
  sed -i "s,ExecStart=$,Environment=\"KUBELET_EXTRA_ARGS=--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.1\"\nExecStart=,g" /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
  sudo systemctl daemon-reload
  sudo systemctl restart kubelet
  # sudo systemctl enable kubelet
}

enable_kubectl() {
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  # sudo chown $(id -u):$(id -g) $HOME/.kube/config
  sudo chown $USER:$GROUP $HOME/.kube/config
}

# for now, better to download from original registry
apply_pod_network() {
  kubectl apply -f $NET_ADD
}

case "$1" in
  "pre")
    update_apt_source
    install_docker
    add_user_to_docker_group
    install_kube_commands
    ;;
  "master")
    sysctl net.bridge.bridge-nf-call-iptables=1
    restart_kubelet
    kubeadm init --config $KUBECONF
    ;;
  "node")
    sysctl net.bridge.bridge-nf-call-iptables=1
    restart_kubelet
    kubeadm join --token $MASTERTOKEN $MASTERIP:$MASTERPORT --discovery-token-ca-cert-hash sha256:$MASTERHASH
    ;;
  "post")
    # if [[ $EUID -eq 0 ]]; then
    #   echo "do not run as root"
    #   exit
    # fi
    enable_kubectl
    apply_pod_network
    ;;
  *)
    echo "huh ????"
    ;;
esac