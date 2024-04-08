#requires -module cloudevents.sdk

<#
    library for hilo connect

    - event templates
#>

function New-ScheduledEvent {
    param(
        [string]$eventType,
        [string]$subject,
        [datetime]$eventTime,
        [string]$data,
        [string]$dataVersion
    )

    $event = @{
        id = [guid]::NewGuid().ToString()
        eventType = $eventType
        subject = $subject
        eventTime = $eventTime
        data = $data | ConvertFrom-Json
        dataVersion = $dataVersion
    }

    return $event
}
