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

groupadd -r munge
useradd -r -g munge munge
mkdir -p /etc/munge /var/lib/munge /var/log/munge /var/run/munge
dd if=/dev/urandom bs=1 count=1024 >/etc/munge/munge.key
chown -R munge:munge /etc/munge/munge.key /etc/munge /var/lib/munge /var/log/munge /var/run/munge
chmod 711 /var/lib/munge
chmod 700 /var/log/munge
chmod 755 /var/run/munge
chmod 700 /etc/munge
chmod 400 /etc/munge/munge.key

groupadd -r slurm
useradd -r -g slurm slurm
mkdir -p /etc/sysconfig/slurm /var/spool/slurmd /var/run/slurmd /var/run/slurmdbd /var/lib/slurmd /var/log/slurm /data
touch /var/lib/slurmd/node_state /var/lib/slurmd/front_end_state /var/lib/slurmd/job_state /var/lib/slurmd/resv_state /var/lib/slurmd/trigger_state /var/lib/slurmd/assoc_mgr_state /var/lib/slurmd/assoc_usage /var/lib/slurmd/qos_usage /var/lib/slurmd/fed_mgr_state
chown slurm:slurm /etc/slurm/slurmdbd.conf
chmod 600 /etc/slurm/slurmdbd.conf
chown -R slurm:slurm /var/*/slurm*

. $SCC_SETUP_ENV
spack install -y --fail-fast slurm+hwloc+mariadb+pmix+readline+restd target=$(arch) ^ glib@:2.74.7 && spack gc -y
spack clean -ab

EOF

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["slurmdbd"]
