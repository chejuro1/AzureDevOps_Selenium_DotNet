                #!/bin/bash
                url="$SYSTEM_TEAMFOUNDATIONSERVERURI/$SYSTEM_TEAMPROJECTID/_apis/build/definitions/$(Build.DefinitionVersion)?api-version=7.1-preview.7"
                echo $url
                assigned_to=$(curl -X GET -u:$(System.AccessToken) $url | jq -r '.authoredBy.uniqueName')
                echo $assigned_to
                echo "##vso[task.setvariable variable=myOutputVar;isoutput=true]$assigned_to"


                url1="$SYSTEM_TEAMFOUNDATIONSERVERURI/$SYSTEM_TEAMPROJECTID/_apis/build/builds/$(Build.BuildId)/timeline?api-version=6.0"
                curl -X GET -u:$(System.AccessToken) $url1 | jq -r '.'
                url3=$(curl -X GET -u:$(System.AccessToken) $url1 | jq -r '.records[] | select(.type == "Task" and .name == "Initialize job") | .log.url')
                echo "URL associated with Task 'passOutput': $url3"

                echo $(risk)
                # Concatenate the strings
                risk="$(risk)"
                risk+=" '' 'The scan url:' $url3"

                # Print the result
                echo "Risk after concatenation: $risk"
                echo "##vso[task.setvariable variable=myOutputVar1;isoutput=true]$risk"