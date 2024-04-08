# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Import required modules
Import-Module Az.Accounts
Import-Module Az.EventGrid

# Get the system-assigned managed identity
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
$managedIdentity = $principal.Identity.Name

# Login with managed identity
Connect-AzAccount -Identity $managedIdentity

# Define Event Grid endpoint and key
$endpoint = "https://<your-event-grid-endpoint>.westus2-1.eventgrid.azure.net/api/events"
$key = "<your-event-grid-key>"

# Define Event Grid event
$event = @{
    id = [guid]::NewGuid().ToString()
    eventType = "recordInserted"
    subject = "myapp/vehicles/motorcycles"
    eventTime = [datetime]::UtcNow
    data = @{
        make = "Ducati"
        model = "Monster"
    }
    dataVersion = "1.0"
}

# Convert event to JSON
$eventJson = $event | ConvertTo-Json

# Send event to Event Grid
Invoke-RestMethod -Method Post -Uri $endpoint -Body $eventJson -Headers @{"aeg-sas-key" = $key}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = "Event sent to Event Grid"
})

<#
using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
if (-not $name) {
    $name = $Request.Body.Name
}

$body = "This HTTP triggered function executed successfully. Pass a name in the query string or in the request body for a personalized response."

if ($name) {
    $body = "Hello, $name. This HTTP triggered function executed successfully."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $body
})
#>
