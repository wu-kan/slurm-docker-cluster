#!/bin/bash
set -e

if [ "$1" = "slurmdbd" ]; then
    . $SCC_SETUP_ENV
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    spack load munge
    gosu munge $(spack location -i munge)/sbin/munged

    echo "---> Starting the Slurm Database Daemon (slurmdbd) ..."

    {
        . /etc/slurm/slurmdbd.conf
        until echo "SELECT 1" | mysql -h $StorageHost -u$StorageUser -p$StoragePass 2>&1 >/dev/null; do
            echo "-- Waiting for database to become active ..."
            sleep 2
        done
    }
    echo "-- Database is now active ..."

    spack load slurm

    exec gosu slurm $(spack location -i slurm)/sbin/slurmdbd -Dvvv
fi

if [ "$1" = "slurmctld" ]; then
    . $SCC_SETUP_ENV
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    spack load munge
    gosu munge $(spack location -i munge)/sbin/munged

    echo "---> Waiting for slurmdbd to become active before starting slurmctld ..."

    until 2>/dev/null >/dev/tcp/slurmdbd/6819; do
        echo "-- slurmdbd is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmdbd is now active ..."

    spack load slurm

    echo "---> Starting the Slurm Controller Daemon (slurmctld) ..."
    if $(spack location -i slurm)/sbin/slurmctld -V | grep -q '17.02'; then
        exec gosu slurm $(spack location -i slurm)/sbin/slurmctld -Dvvv
    else
        exec gosu slurm $(spack location -i slurm)/sbin/slurmctld -i -Dvvv
    fi
fi

if [ "$1" = "slurmd" ]; then
    . $SCC_SETUP_ENV
    echo "---> Starting the MUNGE Authentication service (munged) ..."
    spack load munge
    gosu munge $(spack location -i munge)/sbin/munged

    echo "---> Waiting for slurmctld to become active before starting slurmd..."

    until 2>/dev/null >/dev/tcp/slurmctld/6817; do
        echo "-- slurmctld is not available.  Sleeping ..."
        sleep 2
    done
    echo "-- slurmctld is now active ..."

    spack load slurm

    echo "---> Starting the Slurm Node Daemon (slurmd) ..."
    exec $(spack location -i slurm)/sbin/slurmd -Dvvv
fi

exec "$@"
