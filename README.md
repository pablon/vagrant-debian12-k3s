<div align=center>

  ![Vagrant](https://img.shields.io/badge/-Vagrant-white.svg?style=plastic&logo=vagrant&logoColor=blue)
  ![Debian](https://img.shields.io/badge/-Debian-white.svg?style=plastic&logo=Debian&logoColor=red)
  ![k3s](https://img.shields.io/badge/-k3s-white.svg?style=plastic&logo=k3s) /
  ![Linux](https://img.shields.io/badge/-Linux-gray.svg?style=plastic&logo=Linux)
  ![macOS](https://img.shields.io/badge/-macOS-gray.svg?style=plastic&logo=apple) /
  [![test](https://github.com/pablon/vagrant-debian12-k3s/actions/workflows/test.yml/badge.svg)](https://github.com/pablon/vagrant-debian12-k3s/actions/workflows/test.yml)

  # vagrant-debian12-k3s

</div>

1. Need a quick kubernetes cluster to test some deployments or charts really quick?
2. Don't have `minikube` or `kind`, and want to have it in a VM so you can share your appliance?

This repo creates a Debian 12 VM with Vagrant using VirtualBox driver and installs k3s into it.

## Requirements

- [vagrant](https://developer.hashicorp.com/vagrant/downloads) must be installed
- [virtualbox](https://www.virtualbox.org/wiki/Downloads) must be installed

## Setup

Execute the `run.sh` script

```
./run.sh
```

Then you will be able to run:

```bash
kubectl --kubeconfig outputs/vagrant-k3s.yaml get node -o wide
kubectl --kubeconfig outputs/vagrant-k3s.yaml get all -A
```

or

```bash
export KUBECONFIG="$(pwd)/outputs/vagrant-k3s.yaml"

kubectl config current-context

kubectl get node -o wide
kubectl get all -A
```
