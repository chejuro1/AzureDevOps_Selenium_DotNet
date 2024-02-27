#!/bin/bash

# Store arguments in descriptive variable names
SYSTEM_TEAMFOUNDATIONSERVERURI="$1"
SYSTEM_TEAMPROJECTID="$2"
Build_DefinitionVersion="$3"
SYSTEM_ACCESSTOKEN="$4"
Build_BuildId="$5"
risk="$6"

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

# Get the latest build ID of another build pipeline
other_pipeline_id="1"
branch="main"
latest_build_id=$(curl -s -X GET -u:${SYSTEM_ACCESSTOKEN} "${SYSTEM_TEAMFOUNDATIONSERVERURI}/${SYSTEM_TEAMPROJECTID}/_apis/build/builds?definitions=${other_pipeline_id}&branchName=${branch}&\$top=1&\$orderby=queueTimeDescending&api-version=6.0" | jq -r '.value[0].id')

if [ -z "$latest_build_id" ]; then
  echo "Failed to get the latest build ID of the other pipeline."
  exit 1
fi

url1="${SYSTEM_TEAMFOUNDATIONSERVERURI}/${SYSTEM_TEAMPROJECTID}/_apis/build/builds/${latest_build_id}/timeline?api-version=6.0"
curl -s -X GET -u:${SYSTEM_ACCESSTOKEN} $url1 | jq -r '.'
url3=$(curl -s -X GET -u:${SYSTEM_ACCESSTOKEN} $url1 | jq -r '.records[] | select(.type == "Task" and .name == "Initialize job") | .log.url')
echo "URL associated with Task 'passOutput': $url3"

echo "Risk: $risk"
# Concatenate the strings
risk+=" '' 'The scan url:' $url3"

# Print the result
echo "Risk after concatenation: $risk"
echo "##vso[task.setvariable variable=myOutputVar1;isoutput=true]$risk"

buildurl="${SYSTEM_TEAMFOUNDATIONSERVERURI}/${SYSTEM_TEAMPROJECTID}/_apis/build/builds/${latest_build_id}"
echo "The release URL is: $buildurl"
echo "##vso[task.setvariable variable=myOutputVar2;isoutput=true]$buildurl"
