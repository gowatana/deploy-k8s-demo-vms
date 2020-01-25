# 使用方法

k8s デモむけに、踏み台 1VM、Master 1VM、Worker 3VM をクローンする。  
ただし、ただテンプレート VM をクローンするだけ。

## 1. コンフィグ ファイルを用意する。

config をコピーしてから、環境に合わせて書き換え。

```
PS> cp ./vm_config_SAMPLE.ps1 ./vm_config_xxx.ps1
```

## 2. VM クローン実行。

vCenter に接続して、スクリプトを実行する。

```
PS> Connect-VIServer
PS> ./clone_vms_for_k8s.ps1 ./vm_config_xxx.ps1
```

スクリプト終了時に、作成した VM の一覧が表示される。

```
----- Summary -----
VM Folder: 03-K8s/centos7-k8s-lab-11

VM Summary:

Name        PowerState NumCpu MemoryGB IP                       PG
----        ---------- ------ -------- --                       --
k8s-f-11-01  PoweredOn      2        4 10.0.3.142               vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-m-11-01  PoweredOn      2        4 {10.0.3.170, 10.244.0.1} vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-11-01  PoweredOn      2        4 {10.0.3.171, 10.244.2.1} vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-11-02  PoweredOn      2        4 {10.0.3.169, 10.244.3.1} vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-11-03  PoweredOn      2        4 {10.0.3.140, 10.244.1.1} vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003


----- Inventory -----
[kubernetes-master]
k8s-m-11-01 ansible_host=10.0.3.170

[kubernetes-worker]
k8s-w-11-01 ansible_host=10.0.3.171
k8s-w-11-02 ansible_host=10.0.3.169
k8s-w-11-03 ansible_host=10.0.3.140
-----
```

クローン後に、VM 情報だけ表示するには、-list_mode:$true でスクリプトを実行する。

```
PS C:\deploy-k8s-demo-vms> .\clone_vms_for_k8s.ps1 ..\deploy-k8s-demo-vms_configs-homelab\vm
_config_lab-11.ps1 -list_mode:$true
list_mode pre: True
トランスクリプトが開始されました。出力ファイル: .\logs\clone_k8s-lab-vms_20200125-115902.log
----- vm_config_file check -----


LastWriteTime : 2020/01/24 8:50:54
FullName      : C:\deploy-k8s-demo-vms_configs-homelab\vm_config_lab-11.ps1




----- Summary -----
VM Folder: 03-K8s/centos7-k8s-lab-11

VM Summary:

Name        PowerState NumCpu MemoryGB IP                       PG
----        ---------- ------ -------- --                       --
k8s-f-11-01  PoweredOn      2        4 10.0.3.142               vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-m-11-01  PoweredOn      2        4 {10.0.3.170, 10.244.0.1} vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-11-01  PoweredOn      2        4 {10.0.3.171, 10.244.2.1} vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-11-02  PoweredOn      2        4 {10.0.3.169, 10.244.3.1} vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-11-03  PoweredOn      2        4 {10.0.3.140, 10.244.1.1} vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003


----- Inventory -----
[kubernetes-master]
k8s-m-11-01 ansible_host=10.0.3.170

[kubernetes-worker]
k8s-w-11-01 ansible_host=10.0.3.171
k8s-w-11-02 ansible_host=10.0.3.169
k8s-w-11-03 ansible_host=10.0.3.140
-----


TotalMinutes : 0.01280937
TotalSeconds : 0.7685622



トランスクリプトが停止されました。出力ファイル: C:\deploy-k8s-demo-vms\logs\clone_k8s-lab-vms_20200125-115902.log
PS C:\deploy-k8s-demo-vms>
```
