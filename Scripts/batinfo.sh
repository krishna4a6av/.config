#!/bin/bash
# ~/Scripts/battery-notify-event.sh
# Event-driven battery monitoring using D-Bus and UPower
# Add to Hyprland config: exec-once = ~/Scripts/battery-notify-event.sh &

set -euo pipefail

# Configuration
readonly BAT="${BAT_DEVICE:-/sys/class/power_supply/BAT0}"
readonly CRITICAL_LEVEL=5
readonly LOW_LEVEL=15
readonly FULL_LEVEL=99
readonly SUSPEND_LEVEL=3
readonly SUSPEND_DELAY=10
readonly LOG_FILE="${XDG_RUNTIME_DIR:-/tmp}/battery-monitor.log"

# State variables
last_level="none"
last_status=""
last_capacity=-1
suspend_triggered=false
event_count=0

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

# Check if battery exists
check_battery() {
    if [[ ! -d "$BAT" ]]; then
        log "ERROR: Battery not found at $BAT"
        notify-send -u critical "Battery Monitor Error" "No battery detected"
        exit 1
    fi
}

# Read battery information
get_battery_info() {
    if [[ -f "$BAT/capacity" ]]; then
        capacity=$(<"$BAT/capacity")
    else
        capacity=0
    fi
    
    if [[ -f "$BAT/status" ]]; then
        status=$(<"$BAT/status")
    else
        status="Unknown"
    fi
}

# Handle status changes (charging/discharging)
handle_status_change() {
    local new_status="$1"
    local cap="$2"
    
    if [[ "$new_status" == "$last_status" ]]; then
        return
    fi
    
    log "Status changed: $last_status -> $new_status (${cap}%)"
    
    case "$new_status" in
        "Discharging")
            notify-send -u low "Charger Disconnected" "Running on battery at ${cap}%"
            ;;
        "Charging")
            notify-send -u low "Charger Connected" "Charging started at ${cap}%"
            suspend_triggered=false  # Reset suspend flag
            ;;
        "Full")
            notify-send -u normal "Battery Full" "Battery is fully charged"
            last_level="full"
            ;;
        "Not charging")
            if (( cap >= FULL_LEVEL )); then
                notify-send -u normal "Battery Full" "You can unplug the charger now"
                last_level="full"
            fi
            ;;
    esac
    
    last_status="$new_status"
}

# Handle capacity-based notifications
handle_capacity_change() {
    local cap="$1"
    local stat="$2"
    
    # Only check significant changes (at least 1% difference)
    if (( cap == last_capacity )); then
        return
    fi
    
    if [[ "$stat" == "Discharging" ]]; then
        if (( cap <= SUSPEND_LEVEL )) && ! $suspend_triggered; then
            log "CRITICAL: Battery at ${cap}%, suspending system"
            notify-send -u critical "Battery Critically Low" \
                "System will suspend in ${SUSPEND_DELAY} seconds (${cap}%)"
            suspend_triggered=true
            sleep "$SUSPEND_DELAY"
            systemctl suspend
            
        elif (( cap <= CRITICAL_LEVEL )) && [[ "$last_level" != "critical" ]]; then
            log "Battery critical: ${cap}%"
            notify-send -u critical "Battery Critical" \
                "Battery at ${cap}%. Plug in immediately!"
            last_level="critical"
            
        elif (( cap <= LOW_LEVEL )) && [[ "$last_level" != "low" ]]; then
            log "Battery low: ${cap}%"
            notify-send -u normal "Battery Low" \
                "Battery at ${cap}%. Consider plugging in."
            brightnessctl set 5% 2>/dev/null || true
            last_level="low"
            
        elif (( cap > LOW_LEVEL )) && [[ "$last_level" == "low" || "$last_level" == "critical" ]]; then
            last_level="none"
            log "Battery level recovered: ${cap}%"
        fi
        
    elif [[ "$stat" == "Charging" || "$stat" == "Not charging" ]]; then
        if (( cap >= FULL_LEVEL )) && [[ "$last_level" != "full" ]]; then
            log "Battery full: ${cap}%"
            notify-send -u normal "Battery Full" \
                "You can unplug the charger now (${cap}%)"
            last_level="full"
            
        elif (( cap < FULL_LEVEL - 5 )); then
            last_level="none"
        fi
    fi
    
    last_capacity="$cap"
}

# Main event handler
handle_battery_event() {
    get_battery_info
    handle_status_change "$status" "$capacity"
    handle_capacity_change "$capacity" "$status"
    
    # Log every 100th event to avoid spam
    ((event_count++))
    if (( event_count % 100 == 0 )); then
        log "Processed $event_count events. Current: $status at ${capacity}%"
    fi
}

# Primary method: D-Bus monitoring
monitor_with_dbus() {
    log "Starting D-Bus-based monitoring"
    
    # Get UPower device path
    local upower_path
    upower_path=$(upower -e | grep -i 'battery' | head -n1)
    
    if [[ -z "$upower_path" ]]; then
        log "ERROR: No UPower battery device found"
        return 1
    fi
    
    log "Monitoring UPower device: $upower_path"
    
    # Initial state
    get_battery_info
    last_status="$status"
    last_capacity="$capacity"
    log "Initial state: $status at ${capacity}%"
    
    # Monitor UPower property changes
    # Note: We ignore the "not authorized" warning - eavesdropping works fine for monitoring
    dbus-monitor --system \
        "type='signal',interface='org.freedesktop.DBus.Properties',path='$upower_path'" \
        2>/dev/null | \
    while IFS= read -r line; do
        # Trigger on PropertiesChanged signals
        if [[ "$line" =~ "member=PropertiesChanged" ]]; then
            handle_battery_event
        fi
    done
}

# Fallback method: Polling (if D-Bus fails)
monitor_with_polling() {
    log "Starting polling-based monitoring (fallback)"
    log "WARNING: D-Bus monitoring failed, using 5-second polling"
    
    # Initial state
    get_battery_info
    last_status="$status"
    last_capacity="$capacity"
    log "Initial state: $status at ${capacity}%"
    
    while true; do
        handle_battery_event
        
        # Adaptive polling: faster when critical
        if [[ "$status" == "Discharging" ]] && (( capacity <= CRITICAL_LEVEL )); then
            sleep 1
        else
            sleep 5
        fi
    done
}

# Cleanup on exit
cleanup() {
    log "Battery monitor stopped (processed $event_count events)"
    # Kill any background processes
    jobs -p | xargs -r kill 2>/dev/null || true
}

trap cleanup EXIT INT TERM

# Main function
main() {
    log "=== Battery Monitor Starting ==="
    
    check_battery
    
    # Try D-Bus monitoring (most reliable for sysfs battery events)
    if command -v dbus-monitor &>/dev/null && command -v upower &>/dev/null; then
        log "Using D-Bus monitoring method"
        if ! monitor_with_dbus; then
            log "D-Bus monitoring failed, falling back to polling"
            monitor_with_polling
        fi
    else
        log "D-Bus tools not found, using polling fallback"
        notify-send -u normal "Battery Monitor" \
            "Running in polling mode. Install 'upower' for better performance."
        monitor_with_polling
    fi
}

main
