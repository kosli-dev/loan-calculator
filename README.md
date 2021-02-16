# Loan Calculator Demo

This repository provides a demo project for getting started with the [Merkely DevOps Change Management Platform].

# Getting started

First off, fork or clone this repo so you can follow along.

Secondly, change the owner in [blob/master/Merkelypipe.json#L4](the Merkleypipe pipeline definition) to your user/team in Merkely.

Thirdly, you will need to add three secrets in the github repository settings.

![secrets](images/secrets.png)

# The pipelines

You will notice that this project comes with a CI/CD implementation using github actions.

There is a simple [blob/master/.github/workflows/master_pipeline.yml](master pipeline) following these steps:

* Build and Publish Docker Image
* Declare Merkely Pipeline
* Run test suite and log summary to Merkely
* Run security analysis and log summary to Merkely
* Run coverage and log summary to Merkely
* Deploy to STAGE and log deployment to Merkely

In addition, we have these manually triggered ci pipeline:
* [blob/master/.github/workflows/create_approval.yml](Create Approval)
* [blob/master/.github/workflows/deploy_to_production.yml](Deploy to Production)






