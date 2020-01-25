# VM Clone Config file

$lab_id_string = "k8s-c01"

$number_master_vm = 1
$number_worker_vm = 3
$number_fumidai_vm = 1

$template_vm = "ol77-min-update-20200118"
$dc_name = "infra-dc-01"
$parent_folder_name = "vm"
$new_folder_name = $lab_id_string
$rp_name = "rp-03-lab"
$ds_name = "vsanDatastore"
$pg_name = "vxw-dvs-30-virtualwire-14-sid-10003-ls-lab-k8s-003"
