#!/bin/bash

# Store arguments in descriptive variable names
SYSTEM_TEAMFOUNDATIONSERVERURI="$1"
SYSTEM_TEAMPROJECTID="$2"
Build_DefinitionVersion="$3"
SYSTEM_ACCESSTOKEN="$4"
Build_BuildId="$5"
risk="${@:6}"


echo "SYSTEM_TEAMFOUNDATIONSERVERURI: $SYSTEM_TEAMFOUNDATIONSERVERURI"
echo "SYSTEM_TEAMPROJECTID: $SYSTEM_TEAMPROJECTID"
echo "Build_DefinitionVersion: $Build_DefinitionVersion"
echo "Build_BuildId: $Build_BuildId"
echo "risk: $risk"

url="${SYSTEM_TEAMFOUNDATIONSERVERURI}/${SYSTEM_TEAMPROJECTID}/_apis/build/definitions/${Build_DefinitionVersion}?api-version=7.1-preview.7"
echo "Definition URL: $url"

# Fetch the assigned user
assigned_to=$(curl -s -X GET -u:${SYSTEM_ACCESSTOKEN} $url | jq -r '.authoredBy.uniqueName')
echo "Assigned To: $assigned_to"
echo "##vso[task.setvariable variable=myOutputVar;isoutput=true]$assigned_to"



# Get the URL associated with the log task of the  build pipeline
url1="${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_apis/build/builds/${Build_BuildId}/timeline?api-version=6.0"
echo $url1
curl -s -X GET -u:${SYSTEM_ACCESSTOKEN} $url1 | jq -r '.'

url3=$(curl -s -X GET -u:${SYSTEM_ACCESSTOKEN} $url1 | jq -r '.records[] | select(.type == "Job" and .name == "Build") | .log.url')
echo "URL associated with Task 'passOutput': $url3"

echo "Risk: $risk"
# Concatenate the strings
risk+=" '' 'The scan url:' $url3"


# Print the result
echo "Risk after concatenation: $risk"
echo "##vso[task.setvariable variable=myOutputVar1;isoutput=true]$risk"

# Get the URL of the current pipeline 
buildurl="${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_build/results?buildId=${Build_BuildId}&view=results"

echo "The release URL is: $buildurl"
echo "##vso[task.setvariable variable=myOutputVar2;isoutput=true]$buildurl"


### Get the variable group ID for 'Risk_url'
group_id=$(curl -s -X GET -H "Authorization: Bearer $SYSTEM_ACCESSTOKEN" "${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_apis/distributedtask/variablegroups?api-version=7.1-preview.2" | jq -r '.value[] | select(.name == "Risk_url") | .id')

if [ -z "$group_id" ]; then
  echo "Failed to get the ID of the 'Risk_url' variable group."
  exit 1
fi

# Update the variable 'risk_url1' in the 'Risk_url' variable group
new_value=$risk

# Construct the JSON payload for the update
json_payload='{"id":'${group_id}',
              "type":"Vsts",
              "name":"Risk_url",
              "variables":{"risk_url1":
                            {"isSecret":false,
                              "value":"'${new_value}'"}},
              "variableGroupProjectReferences":[
                        {
                            "name":"Risk_url",
                            "projectReference":
                                {
                                    "id":"8114bf9b-f774-405f-a6b0-f08f2faead2a"  
                                }
                        }
        ]}'

echo "Updating variable 'risk_url1' with value: $new_value"
echo "JSON Payload: $json_payload"

# Make the PUT request to update the variable group
curl -s -X PUT -H "Authorization: Bearer $SYSTEM_ACCESSTOKEN" -H "Content-Type: application/json" -d "${json_payload}" "${SYSTEM_TEAMFOUNDATIONSERVERURI}${SYSTEM_TEAMPROJECTID}/_apis/distributedtask/variablegroups/${group_id}?api-version=7.1-preview.2"
