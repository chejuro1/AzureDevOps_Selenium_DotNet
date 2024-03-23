import requests
import base64
import os
import sys

def set_ado_headers(token):
    ado_credentials = "Basic " + str(base64.b64encode(bytes(':'+token, 'ascii')), 'ascii')
    return {
        'Content-Type': 'application/json',
        'Authorization': ado_credentials
    }

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

def main():
    if len(sys.argv) < 4:
        print("Usage: python script.py <ADO_PAT> <ORGANIZATION_URL> <PROJECT_NAME> <BUILD_ID>")
        exit(1)

    token = sys.argv[1]
    organization_url = sys.argv[2]
    project_name = sys.argv[3]
    build_id = sys.argv[4]

    ado_headers = set_ado_headers(token)
    check_test_automation(organization_url, project_name, build_id, ado_headers)

if __name__ == "__main__":
    main()
