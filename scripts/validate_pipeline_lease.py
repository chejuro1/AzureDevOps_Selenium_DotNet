import requests
import json
import base64
import os
import sys

def set_ado_headers(token):
    ado_credentials = "Basic " + str(base64.b64encode(bytes(':'+token, 'ascii')), 'ascii')
    return {
        'Content-Type': 'application/json',
        'Authorization': ado_credentials
    }

def check_build_retention(organization_url, project_name, build_id, ado_headers):
    get_retention_leases_url = f'{organization_url}/{project_name}/_apis/build/builds/{build_id}/leases?api-version=7.0'

    try:
        retention_lease_response = requests.get(get_retention_leases_url, headers=ado_headers)

        if retention_lease_response.status_code == 200:
            lease_details = json.loads(retention_lease_response.text)
            print_lease_details(lease_details, build_id)
        else:
            print("Failed to get the build retention details.")
            print("Status Code:", retention_lease_response.status_code)
            print("Response:", retention_lease_response.text)
            exit(1)  # Exit the script if unable to get retention details
    except Exception as e:
        print("An error occurred while checking build retention:")
        print(str(e))
        exit(1)  # Exit the script if an error occurs

def print_lease_details(lease_details, build_id):
    valid_entry_found = False

    for entry in lease_details['value']:
        owner_id = entry['ownerId']
        if "User" in owner_id:
            valid_entry_found = True
            lease_id = entry['leaseId']
            run_id = entry['runId']
            retention_time = entry['validUntil']
            print(f"Lease ID: {lease_id}, Run ID: {run_id}, Valid Until: {retention_time}")

    if valid_entry_found:
        print(f"Valid retention entry found for Build ID: {build_id}")
    else:
        print(f"No valid build retention entries found for Build ID: {build_id}")
        print("Please retain the build and try again")
        exit(1)  # Exit the script if no valid retention entries found
##########  
def check_test_automation(organization_url, project_name, build_id, ado_headers):
    # Endpoint to get test runs associated with a build
    get_test_runs_url = f'{organization_url}/{project_name}/_apis/test/runs?buildUri=vstfs:///Build/Build/{build_id}&$top=1&api-version=6.0'

    try:
        response = requests.get(get_test_runs_url, headers=ado_headers)
        response.raise_for_status()
        test_runs_data = response.json()

        if 'value' in test_runs_data and test_runs_data['value']:
            print("Test automation exists for the current build.")
        else:
            print("No test automation found for the current build.")
    except Exception as e:
        print("An error occurred while checking test automation:")
        print(str(e))
#######
def main():
    if len(sys.argv) < 5:
        print("Usage: python script.py <ADO_PAT> <ORGANIZATION_URL> <PROJECT_NAME> <BUILD_ID>")
        exit(1)

    token = sys.argv[1]
    organization_url = sys.argv[2]
    project_name = sys.argv[3]
    build_id = sys.argv[4]

    ado_headers = set_ado_headers(token)
    check_build_retention(organization_url, project_name, build_id, ado_headers)

if __name__ == "__main__":
    main()

    