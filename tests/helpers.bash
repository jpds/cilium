DUMP_FILE=$(mktemp)
MONITOR_PID=""
LAST_LOG_DATE=""

function monitor_start {
	cilium monitor $@ > $DUMP_FILE &
	MONITOR_PID=$!
}

function monitor_resume {
	cilium monitor $@ >> $DUMP_FILE &
	MONITOR_PID=$!
}

function monitor_clear {
	set +x
	sleep 1s
	cp /dev/null $DUMP_FILE
	nstat > /dev/null
	set -x
}

function monitor_dump {
	nstat
	cat $DUMP_FILE
}

function monitor_stop {
	if [ ! -z "$MONITOR_PID" ]; then
		kill $MONITOR_PID || true
	fi
}

function logs_clear {
    LAST_LOG_DATE="$(date +'%F %T')"
}

function abort {
	set +x

	echo "------------------------------------------------------------------------"
	echo "                            Test Failed"
	echo "$*"
	echo ""
	echo "------------------------------------------------------------------------"

	monitor_dump
	monitor_stop

	echo "------------------------------------------------------------------------"
	echo "                            Cilium logs"
	journalctl --since "${LAST_LOG_DATE}" -u cilium
	echo ""
	echo "------------------------------------------------------------------------"

	exit 1
}

function wait_for_endpoints {
	until [ "$(cilium endpoint list | grep ready -c)" -eq "$1" ]; do
	    echo "Waiting for all endpoints to be ready"
	    sleep 2s
	done
}
