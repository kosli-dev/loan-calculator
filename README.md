# Loan Calculator Demo

This repository provides a demo project for getting started with the [Merkely DevOps Change Management Platform].

# Getting started

First off, fork or clone this repo so you can follow along.

Secondly, change the owner in [the Merkleypipe pipeline definition](blob/master/Merkelypipe.json#L4) to your user/team in Merkely.

Thirdly, you will need to add three secrets in the github repository settings.

![secrets](images/secrets.png)

# The pipelines

You will notice that this project comes with a CI/CD implementation using github actions.

There is a [master pipeline](blob/master/.github/workflows/master_pipeline.yml) following these steps:

* Build and Publish Docker Image
* Declare Merkely Pipeline
* Run test suite and log summary to Merkely
* Run security analysis and log summary to Merkely
* Run coverage and log summary to Merkely
* Deploy to STAGE and log deployment to Merkely

In addition, we have these manually triggered ci pipeline:
* [Create Approval](blob/master/.github/workflows/create_approval.yml)
* [Deploy to Production](blob/master/.github/workflows/deploy_to_production.yml)






