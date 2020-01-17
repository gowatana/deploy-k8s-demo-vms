# 使用方法

k8s デモむけに、踏み台 1VM、Master 1VM、Worker 3VM をクローンする。  
ただし、ただテンプレート VM をクローンするだけ。

config をコピーしてから、環境に合わせて書き換え。

```
PS> cp vm_config_SAMPLE.ps1 vm_config_xxx.ps1
```

VM クローン実行。

```
PS> Connect-VIServer
PS> ./clone_vm_k8s-lab_vars.ps1 ./vm_config_SAMPLE.ps1
```
