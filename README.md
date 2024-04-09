<div align=center>

  ![Vagrant](https://img.shields.io/badge/-Vagrant-white.svg?style=plastic&logo=vagrant&logoColor=blue)
  ![Debian](https://img.shields.io/badge/-Debian-white.svg?style=plastic&logo=Debian&logoColor=red)
  ![k3s](https://img.shields.io/badge/-k3s-white.svg?style=plastic&logo=kubernetes)

  For

  ![Linux](https://img.shields.io/badge/-Linux-gray.svg?style=plastic&logo=Linux)
  ![macOS](https://img.shields.io/badge/-macOS-gray.svg?style=plastic&logo=apple)

  # vagrant-debian12-k3s

</div>

Need a quick kubernetes cluster to test some deployments or charts really quick?

This repo creates a Debian 12 VM with Vagrant using VirtualBox driver and installs k3s into it.

# Setup

Execute the `run.sh` script

```
./run.sh
```

Then you will be able to run:

```
kubectl --kubeconfig outputs/vagrant-k3s.yaml get node -o wide
kubectl --kubeconfig outputs/vagrant-k3s.yaml get all -A
```
