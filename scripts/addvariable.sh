#!/bin/bash
SYSTEM_TEAMFOUNDATIONSERVERURI="$1"
SYSTEM_TEAMPROJECTID="$2"
Build_DefinitionVersion="$3"
SYSTEM_ACCESSTOKEN="$4"
Build_BuildId="$5"
risk="$6"
echo $STEM_TEAMFOUNDATIONSERVERURI
echo $SYSTEM_TEAMPROJECTID
echo $Build_DefinitionVersion
echo $Build_BuildId
echo $risk
url="$SYSTEM_TEAMFOUNDATIONSERVERURI/$SYSTEM_TEAMPROJECTID/_apis/build/definitions/$Build_DefinitionVersion?api-version=7.1-preview.7"
echo "Definition URL: $url"

assigned_to=$(curl -X GET -u:$SYSTEM_ACCESSTOKEN $url | jq -r '.authoredBy.uniqueName')
echo "Assigned To: $assigned_to"
echo "##vso[task.setvariable variable=myOutputVar;isoutput=true]$assigned_to"

url1="$SYSTEM_TEAMFOUNDATIONSERVERURI/$SYSTEM_TEAMPROJECTID/_apis/build/builds/$Build_BuildId/timeline?api-version=6.0"
curl -X GET -u:$SYSTEM_ACCESSTOKEN $url1 | jq -r '.'
url3=$(curl -X GET -u:$SYSTEM_ACCESSTOKEN $url1 | jq -r '.records[] | select(.type == "Task" and .name == "Initialize job") | .log.url')
echo "URL associated with Task 'passOutput': $url3"


echo "Risk: $risk"
# Concatenate the strings
risk+=" '' 'The scan url:' $url3"

# Print the result
echo "Risk after concatenation: $risk"
echo "##vso[task.setvariable variable=myOutputVar1;isoutput=true]$risk"

buildurl=$("$SYSTEM_TEAMFOUNDATIONSERVERURI/$SYSTEM_TEAMPROJECTID/_apis/build/builds/$Build_BuildId")
echo "The release URL is : $buildurl"
echo "##vso[task.setvariable variable=myOutputVar2;isoutput=true]$buildurl"


