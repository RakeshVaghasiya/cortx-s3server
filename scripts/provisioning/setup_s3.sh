#!/bin/bash -e

#######################################################
# Install and configure release S3Server installation #
#######################################################

USAGE="USAGE: bash $(basename "$0") [--setupjenkinsyumrepo]
                                    [--installdependency]
                                    [--postdependency]
                                    [--purgeconfigldap]
                                    [--configldap]
                                    [--ldapreplication]
                                    [--olcserverid <Value>]
                                    [--eesnode1 <Value>]
                                    [--eesnode2 <Value>]
                                    [--s3backgrounddelete <Value>]
                                    [--node1 <Value>]
                                    [--node2 <Value>]
                                    [--help | -h]
Install and configure release S3server setup.

where:
--setupjenkinsyumrepo Setup required S3 yum repos.
--installdependency   Install all S3server release rpm dependencies.
--postdependency      Configure S3server post installation of dependencies.
--purgeconfigldap     Clear and Setup all LDAP configs
--configldap          Setup all LDAP configs
--ldapreplication     Setup LDAP replication
--eesnode1            EES node 1 for LDAP replication
--eesnode2            EES node 2 for LDAP replication
--olcserverid         Host olcServerID (Unique for different nodes)
--s3backgrounddelete  Configure s3backgrounddelete and its dependencies
--node1               node 1 for rabbitmq setup
--node2               node 2 for rabbitmq setup
--help                Display this help and exit"

set -e

S3_DIR="/root/s3server"

OS=$(cat /etc/os-release | grep -w ID | cut -d '=' -f 2)
VERSION=`cat /etc/os-release | sed -n 's/VERSION_ID=\"\([0-9].*\)\"/\1/p'`
major_version=`echo ${VERSION} | awk -F '.' '{ print $1 }'`
selinux_status=$(sestatus| grep -w "SELinux status" | cut -d ':' -f 2  | xargs)

olc_server_id=1
ees_node1=127.0.0.1
ees_node2=127.0.0.1
ldap_replication=false
install_dependency=false
post_dependency=false
purge_config_ldap=false
config_ldap=false
setup_jenkins_yum_repo=false
setup_s3backgrounddelete=false
is_rabbitmq_clustered=false

if [ $# -lt 1 ]
then
  echo "$USAGE"
  exit 1
fi

while test $# -gt 0
do
  case "$1" in
    --installdependency )
        install_dependency=true
        ;;
    --postdependency )
        post_dependency=true
        ;;
    --configldap )
        config_ldap=true
        ;;
    --purgeconfigldap )
        purge_config_ldap=true
        ;;
    --ldapreplication )
        ldap_replication=true
        ;;
    --olcserverid ) shift;
        olc_server_id=$1
        ;;
    --eesnode1 ) shift;
        ees_node1=$1
        ;;
    --eesnode2 ) shift;
        ees_node2=$1
        ;;
    --setupjenkinsyumrepo )
        setup_jenkins_yum_repo=true
        ;;
    --s3backgrounddelete )
        setup_s3backgrounddelte=true
        current_node=$2
        ;;
    --node1 ) shift;
        node1=$1
        ;;
    --node2 ) shift;
        node2=$1
        ;;
    --help | -h )
        echo "$USAGE"
        exit 1
        ;;
  esac
  shift
done

setup_release_repo()
{
cat >/etc/yum.repos.d/releases_eos_lustre.repo <<EOL
[releases_eos_lustre]
baseurl = http://ci-storage.mero.colo.seagate.com/releases/eos/integration/centos-7.7.1908/last_successful/
gpgcheck = 0
name = Yum repo for lustre
priority = 1
EOL

cat >/etc/yum.repos.d/releases_eos_halon.repo <<EOL
[releases_eos_halon]
baseurl = http://ci-storage.mero.colo.seagate.com/releases/eos/components/dev/centos-7.7.1908/halon/last_successful/
gpgcheck = 0
name = Yum repo for halon
priority = 1
EOL

cat >/etc/yum.repos.d/releases_eos_mero.repo <<EOL
[releases_eos_mero]
baseurl = http://ci-storage.mero.colo.seagate.com/releases/eos/components/dev/centos-7.7.1908/mero/last_successful/
gpgcheck = 0
name = Yum repo for mero
priority = 1
EOL

cat >/etc/yum.repos.d/releases_eos_s3server.repo <<EOL
[releases_eos_s3server]
baseurl = http://ci-storage.mero.colo.seagate.com/releases/eos/components/dev/centos-7.7.1908/s3server/last_successful/
gpgcheck = 0
name = Yum repo for s3server
priority = 1
EOL

if [ "$major_version" = "7" ];
then

cat >/etc/yum.repos.d/releases_s3server_uploads <<EOL
[releases_s3server_uploads]
baseurl = http://ci-storage.mero.colo.seagate.com/releases/eos/s3server_uploads/
gpgcheck = 0
name = Yum repo for S3 server dependencies
priority = 1
EOL

cat >/etc/yum.repos.d/prvsnr_local_repository <<EOL
[prvsnr_local_repository]
baseurl = http://ci-storage.mero.colo.seagate.com/prvsnr/vendor/centos/epel/
gpgcheck = 0
name = Yum local repo for S3 server dependencies
priority = 1
EOL

elif [ "$major_version" = "8" ];
then

cat >/etc/yum.repos.d/releases_s3server_uploads <<EOL
[releases_s3server_uploads]
baseurl = http://ci-storage.mero.colo.seagate.com/releases/eos/s3server_uploads/centos8/
gpgcheck = 0
name = Yum repo for S3 server dependencies
priority = 1
EOL

# TODO Change it from public to mirror repo, once available
cat >/etc/yum.repos.d/prvsnr_local_repository <<EOL
[prvsnr_local_repository]
baseurl = http://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/
gpgcheck = 0
name = Yum local repo for S3 server dependencies
priority = 1
EOL

fi
}

# Setup required S3 repos for S3 dependencies.
if [[ $setup_jenkins_yum_repo == true ]]
then
setup_release_repo
fi

# Install required S3 release rpm dependencies.
if [[ $install_dependency == true ]]
then
    # Install all required S3 dependencies for release setup
    yum list installed selinux-policy && yum update -y selinux-policy
    yum install -y openssl java-1.8.0-openjdk-headless redis haproxy keepalived

    # Generate the stx certificates rpms
    rm -f ~/rpmbuild/RPMS/x86_64/stx-s3-certs*
    rm -f ~/rpmbuild/RPMS/x86_64/stx-s3-client-certs*

    cd $S3_DIR/rpms/s3certs
    ./buildrpm.sh -T s3dev

    yum remove stx-s3-certs stx-s3-client-certs || /bin/true
    #yum install openldap-servers haproxy -y # so we have "ldap" and "haproxy" users.
    yum localinstall -y ~/rpmbuild/RPMS/x86_64/stx-s3-certs*
    yum localinstall -y ~/rpmbuild/RPMS/x86_64/stx-s3-client-certs*

    # Install rabbitmq requried for s3background delete on all s3 nodes
    curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | sudo bash || exit 1

    # Install python3 pika on all nodes requried for s3backgrounddelete (BSD 3-Clause license)
    if [ "$major_version" = "7" ];
    then
        yum -y install  python36-pika
    elif [ "$major_version" = "8" ];
    then
        yum -y localinstall https://dl.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/p/python3-pika
    fi
fi

setup_ldap_replication()
{
    ldapadd -Y EXTERNAL -H ldapi:/// -f /opt/seagate/s3/install/ldap/syncprov_mod.ldif
    ldapadd -Y EXTERNAL -H ldapi:/// -f /opt/seagate/s3/install/ldap/syncprov.ldif
    firewall-cmd --zone=public --add-port=389/tcp --permanent
    firewall-cmd --reload

    # Openldap replication for 2 node setup for EES.
    sed -i 's/#//g' /opt/seagate/s3/install/ldap/replicate.ldif
    sed -i '0,/<sample_provider_URI>/ s/<sample_provider_URI>/$ees_node1/g' scripts/ldap/replicate.ldif
    sed -i '0,/<sample_provider_URI>/ s/<sample_provider_URI>/$ees_node2/g' scripts/ldap/replicate.ldif
    sed -i 's/olcServerID: /olcServerID: $olc_server_id/g' scripts/ldap/replicate.ldif

    ldapmodify -Y EXTERNAL  -H ldapi:/// -f /opt/seagate/s3/install/ldap/replicate.ldif
}

# Install and Configure Openldap over Non-SSL.
if [[ $purge_config_ldap == true ]]
then
    $S3_DIR/scripts/ldap/setup_ldap.sh --defaultpasswd --forceclean --skipssl
    $S3_DIR/scripts/enc_ldap_passwd_in_cfg.sh -l ldapadmin \
          -p /opt/seagate/auth/resources/authserver.properties

elif [[ $config_ldap == true ]]
then
    $S3_DIR/scripts/ldap/setup_ldap.sh --defaultpasswd --skipssl
    $S3_DIR/scripts/enc_ldap_passwd_in_cfg.sh -l ldapadmin \
          -p /opt/seagate/auth/resources/authserver.propertie
fi

# Setup Openldap replication for EES setup.
if [[ $ldap_replication == true ]]
then
    setup_ldap_replication
fi

# Post S3 dependency installation steps for configuring S3.
if [[ $post_dependency == true ]]
then
    rpm -q openssl java-1.8.0-openjdk-headless redis haproxy keepalived rsyslog stx-s3-certs stx-s3-client-certs|| exit 1
    # Copy haproxy config and rsyslog dependencies
    if [ "$major_version" = "7" ];
    then
        cp /opt/seagate/s3/install/haproxy/haproxy_osver7.cfg /etc/haproxy/haproxy.cfg
    elif [ "$major_version" = "8" ];
    then
        cp /opt/seagate/s3/install/haproxy/haproxy_osver8.cfg /etc/haproxy/haproxy.cfg
    fi

    cp /opt/seagate/s3/install/haproxy/503.http /etc/haproxy/errors/
    cp /opt/seagate/s3/install/haproxy/logrotate/haproxy /etc/logrotate.d/haproxy
    cp /opt/seagate/s3/install/haproxy/rsyslog.d/haproxy.conf /etc/rsyslog.d/haproxy.conf

    if [ -f /etc/cron.daily/logrotate ];
    then
        rm -rf /etc/cron.daily/logrotate
    fi

    cp /opt/seagate/s3/install/haproxy/logrotate/logrotate /etc/cron.hourly/logrotate

    if [ "$selinux_status" = "enabled" ];
    then
        setsebool httpd_can_network_connect on -P
        setsebool haproxy_connect_any 1 -P
    fi

    mkdir -p /var/seagate/s3

    # Update python36 symlinks
    if ! command -v python36 &>/dev/null;
    then
      if command -v python3.6 &>/dev/null;
      then
        ln -s "`command -v python3.6`" /usr/bin/python36
      else
        echo "Python v3.6 is not installed (neither python36 nor python3.6 are found in PATH)."
        exit 1
      fi
    fi

    systemctl restart slapd
    systemctl restart rsyslog

fi

setup_s3backgrounddelete_rabbitmq()
{
    # Start rabbitmq
    systemctl start rabbitmq-server
    # Automatically start RabbitMQ at boot time
    systemctl enable rabbitmq-server
    # Enable RabbitMQ Web Management Console
    rabbitmq-plugins enable rabbitmq_management

    # Setup RabbitMQ Cluster
    # Copy the '.erlang.cookie' file using scp commands from the node1 to node2.
    if [[ $is_rabbitmq_clustered == true && $current_node == "node1" ]];
    then
        echo "Copying '.erlang.cookie' from node1 to node2"
        if [[ ! -z $node2 ]];
        then
            sudo scp /var/lib/rabbitmq/.erlang.cookie root@$node2:/var/lib/rabbitmq/
        else
            echo "Required parameter is missing '--node2'"
            exit 1
        fi
    fi

    systemctl restart rabbitmq-server
    rabbitmqctl stop_app

    # Let RabbitMQ server on node2, join node1
    if [[ $is_rabbitmq_clustered == true && $current_node == "node2" ]];
    then
        echo "Joining the cluster from node2 with node1"
        if [[ ! -z $node1 ]];
        then
            rabbitmqctl join_cluster rabbit@$node1
        else
            echo "Required parameter is missing '--node1'"
            exit 1
        fi
    fi

    rabbitmqctl start_app
    # Check the RabbitMQ cluster status on both nodes
    cluster_result=`rabbitmqctl cluster_status`
    if [[ $cluster_result == *ERROR* ]];
    then
        echo "Rabbitmq cluster status check failed with error message: $cluster_result"
        exit 1
    else
        echo "Rabbitmq cluster status is okay"
    fi

    if [[ $is_rabbitmq_clustered == false || $current_node == "node1" ]];
    then
        # Create a user (In this case user is 's3-background-delete-rabbitmq' with password as 'password')
        rabbitmqctl add_user s3-background-delete-rabbitmq password
        # Setup this user as an administrator.
        rabbitmqctl set_user_tags s3-background-delete-rabbitmq administrator
        rabbitmqctl set_permissions -p / s3-background-delete-rabbitmq ".*" ".*" ".*"
        # Setup queue mirroring
        rabbitmqctl set_policy ha-all ".*" '{"ha-mode":"all"}'
    fi

    echo "Rabbitmq configuration for this node is completed..."
}

# Setup s3backgrounddelete and its dependencies
if [[ $setup_s3backgrounddelte == true ]]
then
    echo "Setting up rabbitmq server.."
    # 1. Setup rabbitmq server
    if [[ ! -z "$current_node" && ! -z "$node1"  &&  ! -z "$node2" ]];
    then
        echo "Configuring Rabbitmq server in clustered mode.."
        is_rabbitmq_clustered=true
    else
        echo "Configuring Rabbitmq server in non-clustered mode.."
        is_rabbitmq_clustered=false
    fi
    setup_s3backgrounddelete_rabbitmq
fi