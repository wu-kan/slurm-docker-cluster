# syntax=docker/dockerfile:1.4
FROM wukan0621/sccenv
COPY slurm.conf /etc/slurm/slurm.conf
COPY slurmdbd.conf /etc/slurm/slurmdbd.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN <<EOF

apt-get update -y
apt-get upgrade -y
apt-get install --no-install-recommends -y \
    gosu
gosu nobody true
apt-get autoremove -y
apt-get clean -y
rm -rf /var/lib/apt/lists/*

mkdir -p /etc/sysconfig/slurm /var/spool/slurmd /var/run/slurmd /var/run/slurmdbd /var/lib/slurmd /var/log/slurm /data /etc/munge
touch /var/lib/slurmd/node_state /var/lib/slurmd/front_end_state /var/lib/slurmd/job_state /var/lib/slurmd/resv_state /var/lib/slurmd/trigger_state /var/lib/slurmd/assoc_mgr_state /var/lib/slurmd/assoc_usage /var/lib/slurmd/qos_usage /var/lib/slurmd/fed_mgr_state

dd if=/dev/urandom bs=1 count=1024 >/etc/munge/munge.key
chmod 700 /etc/munge
chmod 400 /etc/munge/munge.key

groupadd -r --gid=990 slurm
useradd -r -g slurm --uid=990 slurm
chown slurm:slurm /etc/slurm/slurmdbd.conf
chmod 600 /etc/slurm/slurmdbd.conf
chown -R slurm:slurm /var/*/slurm*


. $SCC_SETUP_ENV
spack install -y --fail-fast slurm+hdf5+hwloc+mariadb+pmix+readline+restd target=$(arch) ^ glib@:2.74.7 ^ hdf5~mpi && spack gc -y
spack clean -ab

EOF

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]