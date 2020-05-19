#!/usr/bin/env python

import requests as req
import json
import os

from cdb_utils import parse_cmd_line


def main():
    # TODO parameterize later
    host = "http://server:8001"
    project_file = parse_cmd_line()

    # get git commit header

    # verify gpg signature

    # get PR information

    # verify PR information

if __name__ == '__main__':
    main()
