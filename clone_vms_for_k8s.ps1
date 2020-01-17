$vm_config_file = $args[0]

Get-ChildItem $vm_config_file | Out-Null
if(($? -eq $false) -or ($args.Count -lt 1)){"Config file not exists."; exit 1}
. $vm_config_file

Get-Folder -Type VM -Name $folder_base -ErrorAction:Stop
$folder = Get-Datacenter -Name $dc_name | Get-Folder -Type VM -Name $folder_base | New-Folder -Name $folder_name 

("k8s-f-" + $lab_id.ToString() + "1"),
("k8s-m-" + $lab_id.ToString() + "1"),
("k8s-w-" + $lab_id.ToString() + "1"),
("k8s-w-" + $lab_id.ToString() + "2"),
("k8s-w-" + $lab_id.ToString() + "3")| % {
    Get-VM $template_vm | New-VM -Name $_ `
        -ResourcePool $rp_name `
        -Location $folder `
        -Datastore $ds_name -StorageFormat Thin `
        -RunAsync
}

$clone_wait_interval = 10
$s = 0
while((Get-Task | where {$_.Name -eq "CloneVM_Task"} | where {$_.State -ne "Success"}).Count -ne 0){
    $s += $clone_wait_interval
    sleep $clone_wait_interval
    echo ("clone wait: " + $s + "s")
}

$folder | Get-VM | Sort-Object Name | % {
    $_ | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $pg_name -Confirm:$false | ft -AutoSize
    $_ | Set-VM -NumCpu 2 -MemoryGB 4 -Confirm:$false | ft -AutoSize
    $_ | New-AdvancedSetting -Name disk.EnableUUID -Value True -Confirm:$False | ft -AutoSize
    $_ | Start-VM
    sleep 5
}

$vm_start_wait_sec = 60
"VM Start wait: " + $vm_start_wait_sec + "s"
sleep $vm_start_wait_sec
$folder | Get-VM | select `
    Name,
    PowerState,
    NumCPU,
    MemoryGB,
    @{N="IP";E={$_.Guest.IPAddress | where {$_ -like "*.*"}}},
    @{N="PG";E={($_|Get-NetworkAdapter).NetworkName}} |
    Sort-Object Name | ft -AutoSize