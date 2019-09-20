$lab_id = $args[0]
$template_vm = "go-centos76-template-01"
$folder_base = "01_Go"
$folder_name = "k8s-" + (0 + $lab_id).ToString("00")
$rp_name = "01_go"
$ds_name = "SVT-Datastore"
$pg_name = "Lab-VLAN2219-vSwitch1"
$folder = Get-Folder -Type VM -Name $folder_base | New-Folder -Name $folder_name 

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