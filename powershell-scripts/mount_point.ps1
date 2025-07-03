#############################################################################################################################################
# Script: Mount_Point
#
# Autor: Aron Livi
#
# Esse script foi criado com base no script de monitoração de Storage do Denis Ramalho, ele mapeia os pontos de montagem de disco de uma EC2 
# e retorna o espaço livre e o tamanho disponivel.
# ###########################################################################################################################################

$version = 2 #Mandatory - If any changes in the plugin metrics, increment the plugin version here.
$name = hostname
$name = $name + "_Mount_Point"
$displayname = $name #Nome que o plugin será criado no Site24x7 
$heartbeat = "true" #Mandatory - Setting this to true will alert you when there is a communication problem while posting plugin data to server
Function Get-Data() 
{

    $data = @{}
    $Erro = 0
    $msg = ""
       
        
    try {
        $query = Get-WmiObject -Query "SELECT * FROM Win32_Volume" | ForEach-Object {
            [PSCustomObject]@{
                DriveLetter = $_.DriveLetter
                Label = $_.Label
                Capacity_GB = [math]::Round($_.Capacity / 1GB, 2)
                FreeSpace_GB = [math]::Round($_.FreeSpace / 1GB, 2)
                UsedSpace_GB = [math]::Round(($_.Capacity - $_.FreeSpace) / 1GB, 2)
                UsedSpacePercentage = [math]::Round(($_.UsedSpace / $_.Capacity) * 100, 2)
            }
        }

        # Consulta futura
        foreach ($Label in $query) {
            # Faça algo com cada resultado
            $indice = $query.IndexOf($Label)
            $label = $query[$indice].Label
            $consumo = [math]::Round(($query[$indice].UsedSpace_GB / $query[$indice].Capacity_GB) * 100, 2)
            $data.Add($label, $consumo)              
        }
    }
    catch {
        $Erro += 1
        $msg = $msg + "Ocorreu um erro no plugin!"
    } 
    
    $data.Add("Erro", $Erro)
    $data.Add("msg", $msg)
       
    return $data
}
Function Set-Units() #OPTIONAL - These units will be displayed in the Dashboard
{
    $units = @{}
    $units.Add("Mount Point","%")
    $units.Add("Erro","Erros")

    return $units
}

$mainJson = @{}
$mainJson.Add("plugin_version", $version)
$mainJson.Add("heartbeat_required", $heartbeat)
$mainJson.Add("displayname", $displayname)
$mainJson.Add("data", (Get-Data))
$mainJson.Add("units", (Set-Units))
return $mainJson | ConvertTo-Json
