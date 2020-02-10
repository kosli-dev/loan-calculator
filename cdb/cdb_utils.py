import json
import requests as req

def project_exists_in_cdb(project_data, projects):
    exists = False
    for project in projects:
        if project["name"] == project_data["name"]:
            exists = True
    return exists


def get_project_list_from_cdb(projects_url):
    resp = req.get(projects_url)
    # If the response was successful, no Exception will be raised
    resp.raise_for_status()
    print(resp.text)
    projects = resp.json()
    return projects

def get_project_from_cdb(project_url):
    resp = req.get(project_url)
    # If the response was successful, no Exception will be raised
    resp.raise_for_status()
    print(resp.text)
    project = resp.json()
    return project

def load_project_configuration(json_data_file):
    project_data = json.load(json_data_file)
    print(project_data)
    return project_data