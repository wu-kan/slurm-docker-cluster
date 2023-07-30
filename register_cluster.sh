#!/bin/bash
set -e

docker exec slurmctld bash -c ". \$SCC_SETUP_ENV && spack load slurm && sacctmgr --immediate add cluster name=linux" && \
docker compose restart slurmdbd slurmctld
