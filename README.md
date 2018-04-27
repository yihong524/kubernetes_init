# kubernetes_init

install docker, kubernetes and initialize kubernetes cluster by kubeadm

在天朝特殊网络环境下，加速安装docker,kubernetes并创建kubernetes集群

## 如何使用
```
# 安装 master (在master机器上进行)
git clone git@github.com:EagleChen/kubernetes_init.git
cd kubernetes_init
# 修改 install.sh, 一定要(至少)改前面几个变量， 否则并不会执行成功
sudo ./install.sh pre   # 安装 docker、kube* 等基础工具
# disable swap
sudo swapoff -a 
sudo ./install.sh master   # 利用kubeadm安装master节点
sudo ./install.sh post # 安装网络组件

# 等master安装好, 从输出中获取相关参数，然后安装node (在node机器上进行)
git clone git@github.com:EagleChen/kubernetes_init.git
cd kubernetes_init
# 修改 install.sh, 一定要(至少)改前面几个变量， 否则并不会执行成功
sudo ./install.sh pre   # 安装 docker、kube* 等基础工具
sudo ./install.sh node   # 利用kubeadm把node添加进cluster

# 安装kube dashboard
1. Edit kubernetes-dashboard service 为NodePort
'kubectl -n kube-system edit service kubernetes-dashboard'
2. Apply dashboard YAML
'kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml'


# 安装Heapster
https://github.com/kubernetes/heapster.git

$ kubectl create -f deploy/kube-config/influxdb/
$ kubectl create -f deploy/kube-config/rbac/heapster-rbac.yaml
```

## 注意事项
1. 对照着[官方文档](https://kubernetes.io/docs/setup/independent/install-kubeadm/)使用，本脚本几乎按照官方步骤执行，只是修改了各种下载地址，方便国内特殊网络环境使用
2. 根据自己需求修改`install.sh`
3. 为了简单和直观，`install.sh`脚本没有做过多容错处理，当执行错误时(例如忘记修改相关参数)，并不好重新执行一遍，此时应该拷贝出脚本相关内容，手动执行

## HOSTS
1. 192.168.200.21 -master
2. 192.168.200.22
3. 192.168.200.25
4. 192.168.200.26
账户&密码: root/123.com

## 修改hostname
vim /etc/hostname
vim /etc/hosts

## docker registry
'/etc/docker/daemon.json'
'{
  "registry-mirrors": ["https://mytfd7zc.mirror.aliyuncs.com/"]
}'

kubeadm join --token nifv5r.7fhznip76vpv9bus 192.168.200.21:6443 --discovery-token-ca-cert-hash sha256:414e600b07d6a0bc4ba2f67b3373cadfdea196be95c63a8ded00755fe0bd89d6