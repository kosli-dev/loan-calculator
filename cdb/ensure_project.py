#!/usr/bin/env python

import requests as req

from cdb_utils import project_exists_in_cdb, get_project_list_from_cdb, load_project_configuration, url_for_project


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
        projects_url = url_for_project(host, project_data)

        print("Fetch Project")
        # Todo write integration test for getting project that does not exist
        projects = get_project_list_from_cdb(projects_url)

        print("If project exists exit")
        if project_exists_in_cdb(project_data, projects):
            print("Project exists...exiting")
            return

        print("Create project")
        create_response = req.put(projects_url, json=project_data)
        print(create_response.text)

    #print("If template differs then update template")

    #print("If description differs then update description")


if __name__ == '__main__':
    main()
