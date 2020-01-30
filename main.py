#!/usr/bin/env python
import argparse
import json
from github import Github

# comply github fetch --host https://github.mycompany.com/api/v3 --repo meekrosoft/hadroncollider --pull 2

def log(str):
    ''''Log a string to terminal'''
    print(str)

def github(args):
    log("github")

    if args.command == 'fetch':
        github_fetch(args)

def github_fetch(args):
    log("github fetch")

    log("host: " + str(args.host))
    log("repo: " + str(args.repo))
    log("token: HIDDEN")

    g = Github(str(args.token))
    repo = g.get_repo(args.repo)
    pr = repo.get_pull(2)
    print(pr)

    print("state: ", pr.state)

    reviews = pr.get_reviews()

    print(reviews)
    for review in reviews:
        print(review)
        print("state: ", review.state)
        print(dir(review))


def main(command_line=None):

    parser = argparse.ArgumentParser('comply')
    parser.add_argument(
        '--debug',
        action='store_true',
        help='Print debug info'
    )

    subparsers = parser.add_subparsers(dest='tool')

    github_parser = subparsers.add_parser('github', help='github integrations')
    github_parser.add_argument(
        'command',
        choices=['fetch', 'verify', 'record'],
        help='fetch the pull request, \nverify compliance, \nrecord result in ComplianceDB'
    )
    github_parser.add_argument(
        '--url',
        help='the github api url'
    )
    github_parser.add_argument('--host', help='e.g. https://github.mycompany.com/api/v3 (default=https://api.github.com)', default="https://api.github.com")
    github_parser.add_argument('--repo', help='meekrosoft/hadroncollider', required=True)
    github_parser.add_argument('--token', help='Personal access token for github API', required=True)


    nexus = subparsers.add_parser('nexus', help='nexus integrations')



    args = parser.parse_args(command_line)

    if args.debug:
        print("debug: " + str(args))
    if args.tool == 'github':
        github(args)


if __name__ == '__main__':
    main()
