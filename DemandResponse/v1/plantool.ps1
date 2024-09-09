<#
    .DESCRIPTION
    Generates a set of demand response plans for a set of devices as a zip file in the current directory. Tested on Powershell 5.1+
    .PARAMETER DeviceType
    The device type to generate plans for. Supported: thermostat, chargingPoint, waterHeater. 
    .PARAMETER DeviceCount
    The number of devices to generate plans for. Defaults to 100.
    .PARAMETER CommandCount
    The number of commands to generate for each device. Defaults to 5, resets to 1 for waterHeater.
    .PARAMETER RandomizationInterval
    The randomization interval used to spread commands, in minutes. Defaults to 5.
    .EXAMPLE
    .\plantool.ps1 -DeviceType thermostat [-WhatIf]
#>
[cmdletbinding(SupportsShouldProcess = $true)]
param(
    [parameter()]
    $DeviceCount = 100,
    [parameter()]
    $CommandCount = 5,
    [parameter()]
    $RandomizationInterval = 5,
    [parameter(Mandatory,
    HelpMessage="Enter the device type to generate plans for. Supported: thermostat, chargingPoint, waterHeater.")]
    [ValidateSet("thermostat", "chargingPoint", "waterHeater")]
    [string]$DeviceType,
    [switch]$PassThru)

$outputPath = "tmpPlan"
if (-not (Test-Path $outputPath)) {
    New-Item -Path ".\$outputPath" -ItemType Directory | Out-Null
}

$now = Get-Date
$id = new-guid
$sched = $now.AddDays(1)
$when = get-date -year $sched.Year -Month $sched.Month -Day $sched.Day -Hour 11 -Minute 0 -Second 0 

filter rfc3339 { $_.ToString("yyyy-MM-ddTHH:mm:ssZ") }

if ($DeviceType -eq "thermostat") {
    $commandType = "heatingSetpointDelta"
    $unit = "C"
    function setValue {
        Get-Random -Minimum -6 -Maximum 2
    }
    $deviceName = "tstat"
}
elseif ($DeviceType -eq "chargingPoint") {
    $commandType = "maximumPowerLimit"
    $unit = "W"
    function setValue {
        $( Get-Random -Minimum 0 -Maximum 20 ) * 500
    }
    $deviceName = "chargingPoint"
}
elseif ($DeviceType -eq "waterHeater") {
    $CommandCount = 1
    $commandType = "onOff"
    function setValue {
        $false
    }
    $deviceName = "waterHeater"
}

1..${DeviceCount} | foreach-object {
    $deviceRandomizationInterval = $RandomizationInterval * 60 / $DeviceCount * ( $_ - 1 )

    $plan = [ordered]@{
        "`$schema" = "https://schema.hiloenergie.com/json/v1/demandresponse.schema.json"
        "eventId" = "$($id.guid)"
        "lastModifiedDate" = "$($now | rfc3339)"
        "body" = [ordered]@{
            "deviceId" = "$("$deviceName-0x0000$($_.ToString('X4'))")"
            "commandType" = "$commandType"
            "deviceType" = "$DeviceType"
            "commands" = @()
        }
    }

    $commandArray = 1..$CommandCount
    for ($i=0; $i -lt $commandArray.Length; $i++)
    {
        $command = [ordered]@{
            "parameter" = [ordered]@{}
        }

        if (Test-Path variable:unit) {
            $command.parameter.unit = "$unit"
        }

        $command.parameter.value = $(setValue)
        
        if ( ($CommandCount -gt 1) -and ($i -eq 0) ) {
            $command.start = "$($when.AddSeconds($deviceRandomizationInterval) | rfc3339)"
        }

        elseif ( ($CommandCount -gt 1) -and (0 -lt $i) -and ( $i -lt $commandArray.Length-1 ) ) {
            $command.start = "$($when.AddMinutes($i * 15).AddSeconds($deviceRandomizationInterval) | rfc3339)"
        }

        elseif ($i -eq $CommandArray.Length -1) {
            $command.start = "$($when.AddMinutes($i * 15).AddSeconds($deviceRandomizationInterval) | rfc3339)"
            $command.end = "$($when.AddMinutes($i * 15 + 15).AddSeconds($deviceRandomizationInterval) | rfc3339)"
        }

        $plan.body.commands += $command
    }

    $file = [System.IO.Path]::Combine($outputPath, "partner-deviceplan-${deviceName}0x0000$($_.ToString('X4')).json")
    $($plan | ConvertTo-Json -depth 4) | ForEach-Object {
        $_ | Out-File -FilePath $file -Encoding UTF8
        if ($PassThru) { $_ | ConvertFrom-Json }
    }
}

Compress-Archive -Path $outputPath/* ./plans-"$( Get-Date -Format "yyyy-MM-ddTHH_mm_ss" )".zip
Remove-Item -Recurse -Force $outputPath