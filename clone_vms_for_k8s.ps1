param(
    [string]$vm_config_file,
    [bool]$list_mode = $false
)

# Functions
function generate_vm_name_list {
    param (
        [String]$lab_id_string,
        [String]$vm_name_prefix,
        [Int16]$vm_count
    )
    $vm_name_list = @()
    for($i = 1; $i -le $vm_count; $i++){
        $vm_number_strings = $i.ToString("00")
        $vm_name = $lab_id_string + "-" + $vm_name_prefix + "-" + $vm_number_strings
        $vm_name_list += $vm_name
    }
    return $vm_name_list
}

function generate_ansible_inventory {
    param (
        [String]$group_name,
        [String]$vm_folder_name,
        [array]$vm_name_list
    )
    Write-Host "[$group_name]"
    $vm_name_list | ForEach-Object {
        $vm_name = $_
        $vm = Get-Folder -Type VM -Name $vm_folder_name | Get-VM -Name $vm_name
        $vnic1_ip = $vm.Guest.Nics | where {$_.Device -like "* 1"} |
            select -ExpandProperty IPAddress |
            where {$_ -like "*.*.*.*"} |
            where {$_ -notlike "169.254.*.*"} |
            select -First 1
        "$vm_name ansible_host=$vnic1_ip"
    }
    Write-Host ""
}

$start_time = Get-Date

# Output Log
$timestamp = Get-Date -f "yyyyMMdd-HHmmss"
$log_dir_name = "./logs"
New-Item -ItemType Directory -Path $log_dir_name -ErrorAction:Ignore
$log_file_name = "clone_k8s-lab-vms_" + $timestamp + ".log"
$log_path = Join-Path $log_dir_name $log_file_name
Start-Transcript -Path $log_path

"----- vm_config_file check -----"
if((-Not $vm_config_file) -and ($args.Count -le 1)){"Config file not exists."; exit 1}
Get-ChildItem $vm_config_file -ErrorAction:Stop | fl LastWriteTime, FullName
. $vm_config_file

# Clone Fumidai / Master / Worker VMs
$fumidai_vm_list = generate_vm_name_list $lab_id_string "f" $number_fumidai_vm
$master_vm_list  = generate_vm_name_list $lab_id_string "m" $number_master_vm
$worker_vm_list  = generate_vm_name_list $lab_id_string "w" $number_worker_vm

if($list_mode -eq $false){
    Write-Host "Create VM Folder: $parent_folder_name/$new_folder_name"
    Get-Folder -Type VM -Name $parent_folder_name -ErrorAction:Stop | Out-Null
    $folder = Get-Datacenter -Name $dc_name | Get-Folder -Type VM -Name $parent_folder_name |
        New-Folder -Name $new_folder_name -ErrorAction:Stop

    $vm_clone_tasks = @()
    $fumidai_vm_list | ForEach-Object {
        $vm_name = $_
        Write-Host "Clone VM: $vm_name"
        $vm_clone_tasks += Get-VM $template_vm | New-VM -Name $vm_name `
            -ResourcePool $rp_name -Location $folder `
            -Datastore $ds_name -StorageFormat Thin `
            -RunAsync
    }
    $master_vm_list | ForEach-Object {
        $vm_name = $_
        Write-Host "Clone VM: $vm_name"
        $vm_clone_tasks += Get-VM $template_vm | New-VM -Name $vm_name `
            -ResourcePool $rp_name -Location $folder `
            -Datastore $ds_name -StorageFormat Thin `
            -RunAsync
    }
    $worker_vm_list | ForEach-Object {
        $vm_name = $_
        Write-Host "Clone VM: $vm_name"
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
}

# Info
""
"----- Summary -----"
"VM Folder:"
$folder = Get-Folder -Type VM -Name $parent_folder_name | Get-Folder -Name $new_folder_name
$folder | select Parent,Name
""

"VM Summary:"
$folder | Get-VM | select `
    Name,
    PowerState,
    NumCPU,
    MemoryGB,
    @{N="IP";E={$_.Guest.IPAddress | where {$_ -like "*.*"}}},
    @{N="PG";E={($_|Get-NetworkAdapter).NetworkName}} |
    Sort-Object Name | ft -AutoSize

"----- Inventory -----"
generate_ansible_inventory "fumidai" $new_folder_name $fumidai_vm_list
generate_ansible_inventory "kubernetes-master" $new_folder_name $master_vm_list
generate_ansible_inventory "kubernetes-worker" $new_folder_name $worker_vm_list

$end_time = Get-Date
$end_time - $start_time | fl TotalMinutes,TotalSeconds
Stop-Transcript
