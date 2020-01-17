# 使用方法

k8s デモむけに、踏み台 1VM、Master 1VM、Worker 3VM をクローンする。  
ただし、ただテンプレート VM をクローンするだけ。

config をコピーしてから、環境に合わせて書き換え。

```
PS> cp ./vm_config_SAMPLE.ps1 ./vm_config_xxx.ps1
```

VM クローン実行。

```
PS> Connect-VIServer
PS> ./clone_vms_for_k8s.ps1 ./vm_config_xxx.ps1
```

スクリプト終了時に、作成した VM の一覧が表示される。

```
Name     PowerState NumCpu MemoryGB IP         PG
----     ---------- ------ -------- --         --
k8s-f-31  PoweredOn      2        4 10.0.3.167 vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-m-31  PoweredOn      2        4 10.0.3.168 vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-31  PoweredOn      2        4 10.0.3.169 vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-32  PoweredOn      2        4 10.0.3.170 vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
k8s-w-33  PoweredOn      2        4 10.0.3.171 vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003
```
