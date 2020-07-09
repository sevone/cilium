#!/bin/bash

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source "${dir}/helpers.bash"
# dir might have been overwritten by helpers.bash
dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

TEST_NAME=$(get_filename_without_extension $0)
LOGS_DIR="${dir}/cilium-files/${TEST_NAME}/logs"
redirect_debug_logs ${LOGS_DIR}

set -ex

function cleanup {
  monitor_stop
  cilium policy delete --all 2> /dev/null || true
  docker rm -f mysql-server mysql-client 2> /dev/null || true
}

function finish_test {
  echo cleanup
}

trap finish_test EXIT

SERVER_LABEL="mysql-server"
CLIENT_LABEL="mysql-client"

cleanup
logs_clear

function proxy_init {
  log "beginning proxy_init"
  create_cilium_docker_network

  docker run -dt --net=cilium --name mysql-server -l $SERVER_LABEL -e MYSQL_ROOT_PASSWORD=cilium --publish 6603:3306 mysql:latest
  docker run -dt --net=cilium --name mysql-client -l $CLIENT_LABEL mysql:latest sleep 3600

  wait_for_docker_ipv6_addr mysql-server
  wait_for_docker_ipv6_addr mysql-client

  log "waiting for all 4 endpoints to get an identity"
  while [ `cilium endpoint list -o jsonpath='{range [*]}{.status.identity.id}{"\n"}{end}' | grep '^[0-9]' | grep -v '^5$' | wc -l` -ne 4 ] ; do
    log "waiting..."
    sleep 1
  done

  echo "probing until mysql-server is responsive"
  until docker exec -i mysql-server mysql -uroot -pcilium -e "SHOW DATABASES" 2>&1 >/dev/null; do
      echo "."
      sleep 1
  done
  
  echo "Creating user"
  docker exec -i mysql-server mysql -uroot -pcilium -e "CREATE USER 'cilium'@'%' IDENTIFIED BY 'cilium';"
  echo "Granting privileges"
  docker exec -i mysql-server mysql -uroot -pcilium -e "GRANT ALL ON *.* TO 'cilium'@'%'; FLUSH PRIVILEGES;"

  SERVER_IP4=$(docker inspect --format '{{ .NetworkSettings.Networks.cilium.IPAddress }}' mysql-server)

  echo "Testing client without policy"
  docker exec -i mysql-client mysql -ucilium -pcilium -h$SERVER_IP4 -e "SELECT host FROM mysql.user WHERE User = 'cilium';"

  monitor_start
  log "finished proxy_init"
}

function policy_single_egress {
  cilium policy delete --all
  cat <<EOF | policy_import_and_wait -
[{
    "endpointSelector": {"matchLabels":{"id.server":""}},
    "ingress": [{
        "fromEndpoints": [
	    {"matchLabels":{"reserved:host":""}},
	    {"matchLabels":{"mysql-server":""}}
	]
    }]
},{
    "endpointSelector": {"matchLabels":{"mysql-client":""}},
    "egress": [{
	"toPorts": [{
	    "ports": [{"port": "3306", "protocol": "TCP"}],
	    "rules": {
	        "l7proto": "envoy.mysql",
		"l7": [{}]
	    }
	}]
    }]
}]
EOF
}

#	"toPorts": [{
#	    "ports": [{"port": "3306", "protocol": "TCP"}],
#	    "rules": {
#		"l7proto": "test.passer",
#		"l7": [{}]
#	    }
#	}]

function proxy_test {
  log "beginning MySQL proxy test"
  monitor_clear

  log "trying to reach MySQL server at $SERVER_IP4 from client"
  if docker exec -i mysql-client mysql -ucilium -pcilium -h$SERVER_IP4 -e "SHOW DATABASES;"; then
      echo "Success"
  else
      abort "MySQL query failed"  
  fi

  log "finished MySQL proxy test"
}

proxy_init

policy_single_egress

proxy_test

# log "deleting all policies from Cilium"
# cilium policy delete --all 2> /dev/null || true
# log "removing containers"
# docker rm -f mysql-server mysql-client 2> /dev/null || true

test_succeeded "${TEST_NAME}"
