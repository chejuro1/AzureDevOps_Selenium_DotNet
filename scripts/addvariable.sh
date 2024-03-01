##!/bin/bash

# Store arguments in descriptive variable names
SYSTEM_TEAMFOUNDATIONSERVERURI="$1"
SYSTEM_TEAMPROJECTID="$2"
Build_DefinitionVersion="$3"
SYSTEM_ACCESSTOKEN="$4"
Build_BuildId="$5"
risk="$6"
test-url="${@:7}"
echo "SYSTEM_TEAMFOUNDATIONSERVERURI: $SYSTEM_TEAMFOUNDATIONSERVERURI"
echo "SYSTEM_TEAMPROJECTID: $SYSTEM_TEAMPROJECTID"
echo "Build_DefinitionVersion: $Build_DefinitionVersion"
echo "Build_BuildId: $Build_BuildId"
echo "risk: $risk"
echo "test_url": $test_url

#url="${SYSTEM_TEAMFOUNDATIONSERVERURI}/${SYSTEM_TEAMPROJECTID}/_apis/build/definitions/${Build_DefinitionVersion}?api-version=7.1-preview.7"
urlx="${SYSTEM_TEAMFOUNDATIONSERVERURI}/${SYSTEM_TEAMPROJECTID}/_apis/build/builds/${Build_BuildId}?api-version=7.1-preview.7"
echo "Definition URL: $urlx"


# Fetch the assigned user
assigned_to=$(curl -s -X GET -u:${SYSTEM_ACCESSTOKEN} $urlx | jq -r '.requestedBy.uniqueName')
echo "Assigned To: $assigned_to"
echo "##vso[task.setvariable variable=myOutputVar;isoutput=true]$assigned_to"

# Get the URL associated with the log task of the build pipeline
url1="${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_apis/build/builds/${Build_BuildId}/timeline?api-version=6.0"
echo "Build Timeline URL: $url1"
build_log=$(curl -s -X GET -u:${SYSTEM_ACCESSTOKEN} $url1)
echo $build_log | jq '.'

url3=$(echo $build_log | jq -r '.records[] | select(.type == "Task" and .name == "PowerShell") | .log.url')
echo "URL associated with Task 'PowerShell': $url3"

echo "test_url: $test_url"
# Concatenate the strings
test_url+=" '' 'The scan URL:' $risk"

# Print the result
echo "Risk after concatenation: $test_url"
echo "##vso[task.setvariable variable=myOutputVar1;isoutput=true]$test_url"

# Get the URL of the current pipeline 
buildurl="${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_build/results?buildId=${Build_BuildId}&view=results"
echo "The release URL is: $buildurl"
echo "##vso[task.setvariable variable=myOutputVar2;isoutput=true]$buildurl"

# Get the project ID
project_url="${SYSTEM_TEAMFOUNDATIONSERVERURI}_apis/projects/${SYSTEM_TEAMPROJECTID}?api-version=7.1"
project_response=$(curl -s -X GET -H "Authorization: Bearer $SYSTEM_ACCESSTOKEN" $project_url)
project_id=$(echo $project_response | jq -r '.id')
echo "Project ID: $project_id"

# Get the variable group ID for 'Risk_url'
group_id=$(curl -s -X GET -H "Authorization: Bearer $SYSTEM_ACCESSTOKEN" "${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_apis/distributedtask/variablegroups?api-version=7.1-preview.2" | jq -r '.value[] | select(.name == "Risk_url") | .id')

if [ -z "$group_id" ]; then
  echo "Failed to get the ID of the 'Risk_url' variable group."
  exit 1
fi

# Update the variable 'risk' in the 'Risk_url' variable group
new_value=$test_url

# Construct the JSON payload for the update
json_payload='{
  "id":'${group_id}',
  "type":"Vsts",
  "name":"Risk_url",
  "variables":{
    "risk":{
      "isSecret":false,
      "value":"'${new_value}'"
    }
  },
  "variableGroupProjectReferences":[
    {
      "name":"Risk_url",
      "projectReference":{
        "id":"'$project_id'"
      }
    }
  ]
}'

echo "Updating variable 'risk' with value: $new_value"
echo "JSON Payload: $json_payload"

# Make the PUT request to update the variable group
curl -s -X PUT -H "Authorization: Bearer $SYSTEM_ACCESSTOKEN" -H "Content-Type: application/json" -d "${json_payload}" "${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_apis/distributedtask/variablegroups/${group_id}?api-version=7.1-preview.2"
