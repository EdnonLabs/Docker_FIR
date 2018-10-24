In this repository you will find the container to run FIR in production mode, and a docker-compose to run also a database container.

## Current release

The container are currently tested on FIR commit 9315b23.

## Installation notes

To run all docker instances you can just modify the environment variables in docker-compose.yml file and run ``docker-compose up``, from the directory where you have docker-compose.yml file.

You also can modify the default fixtures to FIR in ``config/fixtures/seed_data.json`` and set default users in ``config/fixtures/dev_users.json``.