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

def get_current_build_id(organization_url, project_name, pipeline_definition_id, ado_headers):
    get_builds_url = f'{organization_url}/{project_name}/_apis/build/builds?definitions={pipeline_definition_id}&$top=1&api-version=7.1-preview.4'

    try:
        response = requests.get(get_builds_url, headers=ado_headers)
        response.raise_for_status()
        build_data = response.json()

        if 'value' in build_data and build_data['value']:
            current_build_id = build_data['value'][0]['id']
            return current_build_id
        else:
            print("No builds found for the specified pipeline definition ID.")
            exit(1)
    except Exception as e:
        print("Failed to get the current build ID:")
        print(str(e))
        exit(1)

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
    except Exception as e:
        print("An error occurred while checking build retention:")
        print(str(e))

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

def main():
    if len(sys.argv) < 4:
        print("Usage: python script.py <ADO_PAT> <ORGANIZATION_URL> <PROJECT_NAME> <PIPELINE_DEFINITION_ID>")
        exit(1)

    token = sys.argv[1]
    organization_url = sys.argv[2]
    project_name = sys.argv[3]
    pipeline_definition_id = sys.argv[4]

    ado_headers = set_ado_headers(token)
    current_build_id = get_current_build_id(organization_url, project_name, pipeline_definition_id, ado_headers)

    check_build_retention(organization_url, project_name, current_build_id, ado_headers)

if __name__ == "__main__":
    main()
