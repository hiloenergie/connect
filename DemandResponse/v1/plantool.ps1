<#
    .DESCRIPTION
    Generates a set of demand response plans for a set of devices.
    .PARAMETER DeviceType
    The device type to generate plans for. Supported: tstat, evcharger. 
    .PARAMETER DeviceCount
    The number of devices to generate plans for. Defaults to 100.
    .PARAMETER CommandCount
    The number of commands to generate for each device. Defaults to 5.
    .EXAMPLE
    .\plantool.ps1 -OutputPath c:\temp\plans [-WhatIf]
#>
[cmdletbinding(SupportsShouldProcess = $true)]
param(
    [parameter()]
    $DeviceCount = 100,
    [parameter()]
    $CommandCount = 5,
    [parameter(Mandatory,
    HelpMessage="Enter the device type to generate plans for. Supported: thermostat, chargingPoint.")]
    [ValidateSet("thermostat", "chargingPoint")]
    [string]$DeviceType,
    [switch]$PassThru)

$OutputPath = "tmpPlan"
if (-not (Test-Path $OutputPath)) {
    New-Item -Path ".\$OutputPath" -ItemType Directory | Out-Null
}

$now = Get-Date
$id = new-guid
$sched = $now.AddDays(1)
$when = get-date -year $sched.Year -Month $sched.Month -Day $sched.Day -Hour 11 -Minute 0 -Second 0 

filter rfc3339 { $_.ToString("yyyy-MM-ddTHH:mm:ssZ") }
filter localTime { $_.ToString("yyyy-MM-ddTHH:mm:ss") }

if ($DeviceType -eq "thermostat") {
    $commandType = "heatingSetpointDelta"
    $planDeviceType = "thermostat"
    $unit = "C"
    function setValue {
        Get-Random -Minimum -6 -Maximum 2
    }
    $deviceName = "tstat"
}
elseif ($DeviceType -eq "chargingPoint") {
    $commandType = "maximumPowerLimit"
    $planDeviceType = "chargingPoint"
    $unit = "W"
    function setValue {
        $( Get-Random -Minimum 0 -Maximum 20 ) * 500
    }
    $deviceName = "chargingPoint"
}

1..${DeviceCount} | foreach-object {
    $plan = [ordered]@{
        "`$schema" = "https://schema.hiloenergie.com/json/v1/demandresponse.schema.json"
        "eventId" = "$($id.guid)"
        "lastModifiedDate" = "$($now | rfc3339)"
        "body" = [ordered]@{
            "deviceId" = "$("$deviceName-0x0000$($_.ToString('X4'))")"
            "commandType" = "$commandType"
            "deviceType" = "$planDeviceType"
            "commands" = @()
        }
    }

    $CommandArray = 1..$CommandCount
    for ($i=0; $i -lt $CommandArray.Length; $i++)
    {
        if ($i -eq 0) {
            $command = [ordered]@{
                "parameter" = [ordered]@{
                    "unit" = "$unit"
                    "value" = $(setValue)
                }
                "start" = "$($when | rfc3339)"
            }
        }

        elseif ( (0 -lt $i) -and ( $i -lt $CommandArray.Length-1 ) ) {
            $command = [ordered]@{
                "parameter" = [ordered]@{
                    "unit" = "$unit"
                    "value" = $(setValue)
                }
                "start" = "$($when.AddMinutes($i * 15) | rfc3339)"
            }                
        }

        elseif ($i -eq $CommandArray.Length -1) {
            $command = [ordered]@{
                "parameter" = [ordered]@{
                    "unit" = "$unit"
                    "value" = $(setValue)
                }
                "start" = "$($when.AddMinutes($i * 15) | rfc3339)"
                "end" = "$($when.AddMinutes($i * 15 + 15) | rfc3339)"
            }
        }

        $plan.body.commands += $command
    }

    $file = [System.IO.Path]::Combine($OutputPath, "partner-deviceplan-${deviceName}0x0000$($_.ToString('X4')).json")
    $($plan | ConvertTo-Json -depth 4) | ForEach-Object {
        $_ | Out-File -FilePath $file -Encoding UTF8
        if ($PassThru) { $_ | ConvertFrom-Json }
    }
}

Compress-Archive -Path $OutputPath/* ./plans-"$($now | localTime)".zip
Remove-Item -Recurse -Force $OutputPath