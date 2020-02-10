#!/usr/bin/env python

import requests as req

from cdb_utils import project_exists_in_cdb, get_project_from_cdb, load_project_configuration


def main():
    """
    host
    project.json
    """

    #TODO parameterize later
    host = "http://hub"
    project_file = "project.json"

    print("Ensure Project - loading " + project_file)
    with open(project_file) as json_data_file:
        project_data = load_project_configuration(json_data_file)
        project_url = host + '/api/v1/projects/' + project_data["owner"] + '/' + project_data["name"]

        print("Fetch Project")
        # Todo write integration test for getting project that does not exist
        projects = get_project_from_cdb(project_url)

        print("Create artifact")
        #create_response = req.put(projects_url, json=project_data)
        #print(create_response.text)


if __name__ == '__main__':
    main()
