param (
    [string]$SYSTEM_TEAMFOUNDATIONSERVERURI,
    [string]$SYSTEM_TEAMPROJECTID,
    [string]$SYSTEM_ACCESSTOKEN
)

Write-Host "SYSTEM_TEAMFOUNDATIONSERVERURI: $SYSTEM_TEAMFOUNDATIONSERVERURI"
Write-Host "SYSTEM_TEAMPROJECTID: $SYSTEM_TEAMPROJECTID"

# Get the variable group ID for 'Risk_url'
$url = ('{0}{1}/_apis/distributedtask/variablegroups?api-version=7.1-preview.2' -f $SYSTEM_TEAMFOUNDATIONSERVERURI, $SYSTEM_TEAMPROJECTID)
$response = Invoke-RestMethod -Uri $url -Headers @{Authorization = "Bearer $SYSTEM_ACCESSTOKEN"}
$group_id = ($response.value | Where-Object { $_.name -eq "Risk_url" }).id

if (-not $group_id) {
    Write-Host "Failed to get the ID of the 'Risk_url' variable group."
    exit 1
}

# Update the variable 'risk_url1' in the 'Risk_url' variable group
$json = '{
    "id": ' + $group_id + ',
    "type": "Vsts",
    "name": "Risk_url",
    "variables": {
        "risk_url1": {
            "isSecret": false,
            "value": "https://dev.azure.com/cheindjou/poc/_build/results?buildId=215&view=logs"
        }
    }
}'

Write-Host "Updating variable 'risk_url1' with value: https://dev.azure.com/cheindjou/poc/_build/results?buildId=215&view=logs"
Write-Host "JSON Payload: $json"

# Make the PATCH request to update the variable group
$patchUrl = "${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_apis/distributedtask/variablegroups/${group_id}?api-version=7.1-preview.2"
Invoke-RestMethod -Uri $patchUrl -Method Put -Body $json -ContentType "application/json" -Headers @{Authorization = "Bearer $SYSTEM_ACCESSTOKEN"}
