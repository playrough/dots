#!/usr/bin/env bash

LOCK=/tmp/battery.lock

if [ -e "$LOCK" ]; then
	echo "already running"
	exit 1
fi

touch "$LOCK"
trap "rm -f $LOCK" EXIT

WARNING=20
CRITICAL=10
SUSPEND=1

BAT=$(find /sys/class/power_supply -maxdepth 1 -name "BAT*" | head -n1)

[ -z "$BAT" ] && exit 1

warn_sent=0
critical_sent=0

notify() {
	notify-send \
		-h string:x-canonical-private-synchronous:battery \
		"$1" "$2"
}

# =========================

# Battery level monitor

# =========================

battery_loop() {
	while true; do
		capacity=$(<"$BAT/capacity")
		status=$(<"$BAT/status")

		if [[ "$status" == "Discharging" ]]; then

			if ((capacity <= WARNING && warn_sent == 0)); then
				notify "󱊡 Low Battery" "${capacity}% remaining"
				warn_sent=1
			fi

			if ((capacity <= CRITICAL && critical_sent == 0)); then
				notify "󱃍 Critical Battery" "${capacity}% remaining"
				critical_sent=1
			fi

			if ((capacity <= SUSPEND)); then
				notify " Battery Critical" \
					"Suspending in 10 seconds"

				sleep 10
				systemctl suspend
			fi

		else
			warn_sent=0
			critical_sent=0
		fi

		sleep 30
	done

}

# =========================

# Charger plug/unplug monitor

# =========================

status_monitor() {
	last=""

	while read -r _; do
		status=$(<"$BAT/status")
		capacity=$(<"$BAT/capacity")

		[[ "$status" == "$last" ]] && continue

		case "$status" in
		Charging)
			notify " Charger Connected" \
				"Battery ${capacity}%"
			;;
		Discharging)
			notify "󰁹 Running On Battery" \
				"Battery ${capacity}%"
			;;
		Full)
			notify "󰁹 Battery Full" \
				"${capacity}%"
			;;
		esac

		last="$status"
	done < <(upower --monitor-detail)

}

battery_loop &
status_monitor
