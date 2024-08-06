<#
    .DESCRIPTION
    Generates a set of demand response plans for a set of thermostats.
    .PARAMETER OutputPath
    The path to the directory where the plans will be written.
    .PARAMETER TstatCount
    The number of thermostats to generate plans for. Defaults to 100.
    .PARAMETER CommandCount
    The number of commands to generate for each thermostat. Defaults to 5.
    .EXAMPLE
    .\plantool.ps1 -OutputPath c:\temp\plans [-WhatIf]
#>
[cmdletbinding(SupportsShouldProcess = $true)]
param(
    [parameter(Mandatory)]
    [string]$OutputPath,
    [parameter()]
    $TstatCount = 100,
    [parameter()]
    $CommandCount = 5,
    [switch]$PassThru)

if (-not (Test-Path $OutputPath)) {
    throw "OutputPath '$OutputPath' does not exist"
    return
}

$now = Get-Date
$id = new-guid
$sched = $now.AddDays(1)
$when = get-date -year $sched.Year -Month $sched.Month -Day $sched.Day -Hour 10 -Minute 0 -Second 0 

filter rfc3339 { $_.ToString("yyyy-MM-ddTHH:mm:ssZ") }

1..${TstatCount} | foreach-object {
    $plan =
    @"
{
    "`$schema": "https://schema.hiloenergie.com/json/v1/demandresponse.schema.json",
    "eventId": "$($id.guid)",
    "lastModifiedDate": "$($now | rfc3339)",
    "body": {
        "deviceId": "$("tstat-0x0000$($_.ToString('X4'))")",
        "commandType": "heatingSetpointDelta",
        "deviceType": "thermostat",
        "commands": [
$(  $CommandArray = 1..$CommandCount
    for ($i=0; $i -lt $CommandArray.Length; $i++)
    {
        if ($i -eq 0)
        {
            @"
            {
                "parameter": {
                    "unit": "C",
                    "value": $(Get-Random -Minimum -6 -Maximum 2)
                },
                "start": "$($when | rfc3339)"
            },`r`n
"@ # end of inner here-string   
        }

        elseif ( (0 -lt $i) -and ( $i -lt $CommandArray.Length-1 ) )
        {
            @"
            {
                "parameter": {
                    "unit": "C",
                    "value": $(Get-Random -Minimum -6 -Maximum 2)
                },
                "start": "$($when.AddMinutes($i * 15) | rfc3339)"
            },`r`n
"@ # end of inner here-string   
        }

        elseif ($i -eq $CommandArray.Length -1)
        {
            @"
            {
                "parameter": {
                    "unit": "C",
                    "value": $(Get-Random -Minimum -6 -Maximum 2)
                },
                "start": "$($when.AddMinutes($i * 15) | rfc3339)",
                "end": "$($when.AddMinutes($i * 15 + 15) | rfc3339)"
            }
"@ # end of inner here-string   
        }
    })
        ]
    }
}
"@ # end of outer here-string
    $file = [System.IO.Path]::Combine($OutputPath, "tstat-0x0000$($_.ToString('X4')).json")
    $plan | ForEach-Object {
        $_ | Out-File -FilePath $file -Encoding UTF8
        if ($PassThru) { $_ | ConvertFrom-Json }
    }
}
