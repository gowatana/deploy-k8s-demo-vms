$vm_config_file = $args[0]
Get-ChildItem $vm_config_file | Out-Null
if(($? -eq $false) -or ($args.Count -lt 1)){"Config file not exists."; exit 1}
. $vm_config_file

$lab_id_strings = $lab_id.ToString("00")
Get-Folder -Type VM -Name $parent_folder_name -ErrorAction:Stop | Out-Null
$folder = Get-Datacenter -Name $dc_name | Get-Folder -Type VM -Name $parent_folder_name |
    New-Folder -Name $new_folder_name -ErrorAction:Stop

# Fumidai VMs
$fumidai_vm_list = @()
for($i = 1; $i -le $number_fumidai_vm; $i++){
    $vm_number_strings = $i.ToString("00")
    $vm_name_prefix = "k8s-f-"
    $fumidai_vm_list += $vm_name_prefix + $lab_id_strings + "-" + $vm_number_strings
}

# Master VMs
$master_vm_list = @()
for($i = 1; $i -le $number_master_vm; $i++){
    $vm_number_strings = $i.ToString("00")
    $vm_name_prefix = "k8s-m-"
    $master_vm_list += $vm_name_prefix + $lab_id_strings + "-" + $vm_number_strings
}

# Worker VMs
$worker_vm_list = @()
for($i = 1; $i -le $number_worker_vm; $i++){
    $vm_number_strings = $i.ToString("00")
    $vm_name_prefix = "k8s-w-"
    $worker_vm_list += $vm_name_prefix + $lab_id_strings + "-" + $vm_number_strings
}

$vm_clone_tasks = @()
$fumidai_vm_list + $master_vm_list + $worker_vm_list | ForEach-Object {
    $vm_name = $_
    "Clone VM: $vm_name"
    $vm_clone_tasks += Get-VM $template_vm | New-VM -Name $vm_name `
        -ResourcePool $rp_name -Location $folder `
        -Datastore $ds_name -StorageFormat Thin `
        -RunAsync
}

$clone_wait_interval = 10
$s = 0
while((Get-Task -Id ($vm_clone_tasks.Id) | where {$_.State -ne "Success"}).Count -ne 0){
    $s += $clone_wait_interval
    sleep $clone_wait_interval
    Write-Host ("Clone wait: " + $s + "s")
}

$folder | Get-VM | Sort-Object Name | ForEach-Object {
    $_ | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $pg_name -Confirm:$false | ft -AutoSize
    $_ | Set-VM -NumCpu 2 -MemoryGB 4 -Confirm:$false | ft -AutoSize
    $_ | New-AdvancedSetting -Name disk.EnableUUID -Value True -Confirm:$False | ft -AutoSize
    $_ | Start-VM
    sleep 5
}

$vm_start_wait_sec = 60
Write-Host ("VM Start wait: " + $vm_start_wait_sec + "s")
sleep $vm_start_wait_sec
$folder | Get-VM | select `
    Name,
    PowerState,
    NumCPU,
    MemoryGB,
    @{N="IP";E={$_.Guest.IPAddress | where {$_ -like "*.*"}}},
    @{N="PG";E={($_|Get-NetworkAdapter).NetworkName}} |
    Sort-Object Name | ft -AutoSize

# Generate Ansible Inventory
"----- Inventory"
"[kubernetes-master]"
$master_vm_list | ForEach-Object {
    $vm_name = $_
    $vm = Get-Folder -Type VM -Name $new_folder_name | Get-VM -Name $vm_name
    $vnic1_ip = $vm.Guest.Nics | where {$_.Device -like "* 1"} |
        select -ExpandProperty IPAddress |
        where {$_ -like "*.*.*.*"} |
        where {$_ -notlike "169.254.*.*"} |
        select -First 1
    "$vm_name ansible_host=$vnic1_ip"
}

""
"[kubernetes-worker]"
$worker_vm_list | ForEach-Object {
    $vm_name = $_
    $vm = Get-Folder -Type VM -Name $new_folder_name | Get-VM -Name $vm_name
    $vnic1_ip = $vm.Guest.Nics | where {$_.Device -like "* 1"} |
        select -ExpandProperty IPAddress |
        where {$_ -like "*.*.*.*"} |
        where {$_ -notlike "169.254.*.*"} |
        select -First 1
    "$vm_name ansible_host=$vnic1_ip"
}
"-----"
