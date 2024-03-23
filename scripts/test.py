import requests
import json
import os
import base64
import time
import sys
from datetime import datetime, timedelta

# Configuration
# Additional Scan Pipeline ID and name are hard coded. Need to parameterize it.
mend_scan_buffer_time = 24

def set_ado_headers(token):
    ado_credentials = "Basic " + str(base64.b64encode(bytes(':'+token, 'ascii')), 'ascii')
    return {
        'Content-Type': 'application/json',
        'Authorization': ado_credentials
    }

def get_last_pipeline_run(organization_url, project_name, pipeline_definition_id, ado_headers):
    get_all_pipelines_url = f'{organization_url}/{project_name}/_apis/pipelines/{pipeline_definition_id}/runs?api-version=7.0'
    try:
        all_pipeline_runs_response = requests.get(get_all_pipelines_url, headers=ado_headers)
        all_pipeline_runs_response.raise_for_status()
        pipeline_runs = all_pipeline_runs_response.json()['value']

        if pipeline_runs:
            last_run = pipeline_runs[0]
            print("Successfully retrieved the pipeline data")
            return last_run
        else:
            exit(1)
    except Exception as e:
        print("Failed to get the pipelines data.")
        print(str(e))
        exit(1)

def prepData(json_data, organization_url, project_name):
    runId = json_data['id']
    finishedDate = json_data['finishedDate']
    if runId and finishedDate:
        pipeline_url = f'{organization_url}/{project_name}/_build/results?buildId={runId}&view=artifacts&pathAsName=false&type=publishedArtifacts'
        
        print("##vso[task.setvariable variable=preProductionMendScanResultsURL;isOutput=true]" + pipeline_url)
        print("##vso[task.setvariable variable=preProductionMendScanRunResult;isOutput=true]" + json_data['result'])
        print("##vso[task.setvariable variable=preProductionMendScanFinishedDateTime;isOutput=true]" + json_data['finishedDate'])
        print("##vso[task.setvariable variable=preProductionMendScanRunStatus;isOutput=true]" + json_data['state'])
        print("##vso[task.setvariable variable=preProductionMendScanbuildId;isOutput=true]" + str(json_data['id']))
        print("##vso[task.setvariable variable=Number of Critical SCA Vulnerabilities;isOutput=true]" + "0")
        print("##vso[task.setvariable variable=Number of High SCA Vulnerabilities;isOutput=true]" + "0")
        print("##vso[task.setvariable variable=Tool;isOutput=true]" + "Mend")

def validate_scan_time(scan_time, planned_start_time):
    input_str = scan_time[:-9].replace('T', ' ')
    input_datetime = datetime.strptime(input_str, '%Y-%m-%d %H:%M:%S')

    current_time = datetime.strptime(planned_start_time, '%Y-%m-%d %H:%M:%S')
    
    if (current_time > input_datetime):
        time_difference = current_time - input_datetime
    
        if abs(time_difference) > timedelta(hours=mend_scan_buffer_time):
            print("The scan time exceeds the " + str(mend_scan_buffer_time) + "-hour limit. Exiting.")
            exit(1)
        else:
            return True
    else:
        print("The scheduled deployment start date is prior to the time when the mend scan was conducted.")
        exit(1)

def check_build_retention_value(mend_build_id_num, organization_url, project_name, ado_headers):
    get_retention_leases_for_build = f'{organization_url}/{project_name}/_apis/build/builds/{mend_build_id_num}/leases?api-version=7.0'
    retention_lease_response = requests.get(get_retention_leases_for_build, headers=ado_headers)

    if retention_lease_response.status_code == 200:
        lease_details = json.loads(retention_lease_response.text)
        print_lease_details(lease_details, mend_build_id_num)    
    else:
        print("Failed to get the build retention details" + str(retention_lease_response.status_code))
        print(lease_details)
        exit(1)

def print_lease_details(lease_details, mend_build_id_num):
    # Flag to check if a valid entry is found
    valid_entry_found = False

    for entry in lease_details['value']:
        owner_id = entry['ownerId']
        if "User" in owner_id:
            valid_entry_found = True
            buildRunId = entry['runId']
            retention_time = entry['validUntil']
			
            retention_time = retention_time[:-1].replace('T', ' ')
            input_retention_str = datetime.strptime(retention_time, '%Y-%m-%d %H:%M:%S')
            current_time = datetime.utcnow()
            retention_difference = input_retention_str - current_time
			
            if (retention_difference > timedelta(days=2555)):
                print("##vso[task.setvariable variable=SCA Scan No Expiry]" + "True")
            else:
                print("##vso[task.setvariable variable=SCA Scan No Expiry]" + "False")

    if valid_entry_found and mend_build_id_num == str(buildRunId):
        print(f"Valid entry found: Lease ID: {entry['leaseId']}, Run ID = {entry['runId']}, Lease Owner ID: {entry['ownerId']},  Created On: {entry['createdOn']}, Valid Until = {entry['validUntil']}")
    
    else: 
        print(f"No valid build retention entries found. Please retain the build and re-run the pipeline. Refer to https://learn.microsoft.com/en-us/azure/devops/pipelines/policies/retention?view=azure-devops&tabs=yaml for more details. Skipping further checks.")
        exit(1)

def check_test_result_retention_value(organization_url, project_name, ado_headers):
    get_test_retention = f'{organization_url}/{project_name}/_apis/test/resultretentionsettings?api-version=7.0'
    get_test_results_retention_settings = requests.get(get_test_retention, headers=ado_headers)
    
    if get_test_results_retention_settings.status_code == 200: 
        data = json.loads(get_test_results_retention_settings.text)
        if data['automatedResultsRetentionDuration'] == -1 and data['manualResultsRetentionDuration'] == -1:
            print("Test Result retention set to Never Delete")
            print("##vso[task.setvariable variable=automatedResultsRetentionStatus]" + "Never Delete")
            print("##vso[task.setvariable variable=manualResultsRetentionStatus]" + "Never Delete")
            print("##vso[task.setvariable variable=ADO Manual Test Results No Expiry]" + "TRUE")
        else: 
            print("Please verify the project test retention settings and re-run the deployment")
            print("##vso[task.setvariable variable=ADO Manual Test Results No Expiry]" + "FALSE")
            print(data)
            exit(1)
    else
