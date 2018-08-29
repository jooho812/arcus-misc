#!/bin/bash
#
#  tc uses the following units when passed as a parameter.
#  kbps: Kilobytes per second
#  mbps: Megabytes per second
#  kbit: Kilobits per second
#  mbit: Megabits per second​
#  bps: Bytes per second
#       Amounts of data can be specified in:
#       kb or k: Kilobytes
#       mb or m: Megabytes
#       mbit: Megabits
#       kbit: Kilobits
#  To get the byte figure from bits, divide the number by 8 bit
#

#
# Name of the traffic control command.
TC=/sbin/tc

# The network interface we're planning on limiting bandwidth.
IF=eth0             # Interface

# Download limit (in mega bits)
DNLD=1kbps          # DOWNLOAD Limit

# Upload limit (in mega bits)
UPLD=1kbps          # UPLOAD Limit

# IP address of the machine we are controlling
if [ -z "$2" ];
then
  PORT=20121    # Port we throttle from/to
else
  PORT=$2
fi

# Filter options for limiting the intended interface.
U32="$TC filter add dev $IF protocol ip parent 1:0 prio 1 u32"

start() {

# We'll use Hierarchical Token Bucket (HTB) to shape bandwidth.
# For detailed configuration options, please consult Linux man
# page.

        $TC qdisc add dev $IF root handle 1: htb default 30
        $TC class add dev $IF parent 1: classid 1:1 htb rate $DNLD
        $TC class add dev $IF parent 1: classid 1:2 htb rate $UPLD
        $U32 match ip dport $PORT 0xffff flowid 1:1
        $U32 match ip sport $PORT 0xffff flowid 1:2

# The first line creates the root qdisc, and the next two lines
# create two child qdisc that are to be used to shape download
# and upload bandwidth.
#
# The 4th and 5th line creates the filter to match the interface.
# see http://lartc.org/howto/lartc.qdisc.filters.html
}

stop() {

# Stop the bandwidth shaping.
        $TC qdisc del dev $IF root

}

restart() {

# Self-explanatory.
        stop
        sleep 1
        start

}

show() {

# Display status of traffic control status.
        $TC -s qdisc ls dev $IF

}

case "$1" in

start)

echo -n "Starting bandwidth shaping: "
start
echo "done"
;;

stop)

echo -n "Stopping bandwidth shaping: "
stop
echo "done"
;;

restart)

echo -n "Restarting bandwidth shaping: "
restart
echo "done"
;;

show)

echo "Bandwidth shaping status for $IF:"
show
echo ""
;;

*)

pwd=$(pwd)
    echo "Usage: $0 {start|stop|restart|show}"
    ;;

    esac

    exit 0
