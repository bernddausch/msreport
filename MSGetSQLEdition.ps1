$Scriptblock = {
    # SQL Pfade fuer 32 und 64 bit
    $RegPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server"
    )

    foreach ($BasePath in $RegPaths) {
        if (Test-Path $BasePath) {
            $Instances = (Get-ItemProperty -Path $BasePath -ErrorAction SilentlyContinue).InstalledInstances
            
            foreach ($Instance in $Instances) {
                # Ermittelt den internen Instanz-Pfad aus dem jeweiligen Architektur-Zweig
                $InstanceMappingPath = "$BasePath\Instance Names\SQL"
                $InstanceID = (Get-ItemProperty -Path $InstanceMappingPath -ErrorAction SilentlyContinue).$Instance
                
                if ($InstanceID) {
                    $SetupPath = "$BasePath\$InstanceID\Setup"
                    $VersionInfo = Get-ItemProperty -Path $SetupPath -ErrorAction SilentlyContinue
                    
                    if ($VersionInfo) {
                        # Erkennung der Architektur anhand des Registry-Pfads
                        $Architecture = if ($BasePath -like "*Wow6432Node*") { "32-Bit (WoW64)" } else { "64-Bit (Nativ)" }

                        [PSCustomObject]@{
                            "Instanzname"   = $Instance
                            "Version"       = $VersionInfo.Version
                            "Edition"       = $VersionInfo.Edition
                        }
                    }
                }
            }
        }
    }
}

$Computers = get-content -path "SQLComputers.txt"
$DNSDomain = $ENV:USERDNSDOMAIN

ForEach ($computer in $computers) {
    $fqdn = "$($computer).$($DNSDomain)"
    If (Resolve-DNSName -name $fqdn -ErrorAction SilentlyContinue) {
        Invoke-Command -computername $fqdn -Scriptblock $Scriptblock
    }
}