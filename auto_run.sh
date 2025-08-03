#!/bin/sh

AUTO_RUN_DIR="/data/auto_run"
LOADER_NAME="auto_run.sh"

auto_run() {
    # auto run script at startup.
    echo -e "\033[32mSearching for scripts...\033[0m"
    echo "Searching for scripts..." >> /tmp/log/auto_run.log
    cd "$AUTO_RUN_DIR" || {
        echo -e "\033[31mError: Cannot access $AUTO_RUN_DIR\033[0m" >&2
        echo "Error: Cannot access $AUTO_RUN_DIR" >> /tmp/log/auto_run.log
        return 1
    }
    for script in *.sh; do
        [ "$script" = "$LOADER_NAME" ] && continue
        echo -e "\033[33mExecuting: $script...\033[0m"
        echo "Executing: $script..." >> /tmp/log/auto_run.log
        if ! /bin/sh "$script"; then
            echo -e "\033[31mError: Failed to execute $script\033[0m" >&2
            echo "Error: Failed to execute $script" >> /tmp/log/auto_run.log
        fi
    done
    echo -e "\033[32mAuto run scripts completed!\033[0m"
    echo "Auto run scripts completed!" >> /tmp/log/auto_run.log
}

enable() {
    # Add script to system autostart
    uci set firewall.auto_run=include
    uci set firewall.auto_run.type='script'
    uci set firewall.auto_run.path="${AUTO_RUN_DIR}/${LOADER_NAME}"
    uci set firewall.auto_run.enabled='1'
    uci commit firewall
    if ! iptables -L | grep -q "/* !fw3"; then
        echo -e "\033[33mFirewall not started! Adding cron task...\033[0m"
        grep -v "${LOADER_NAME}" /etc/crontabs/root > /etc/crontabs/root.new
        echo "*/1 * * * * /bin/sh ${AUTO_RUN_DIR}/${LOADER_NAME} >/dev/null 2>&1" >> /etc/crontabs/root.new
        mv /etc/crontabs/root.new /etc/crontabs/root
        /etc/init.d/cron restart
    fi
    echo -e "\033[32mauto_run has been enabled!\033[0m"
}
disable() {
    # Remove scripts from system autostart
    uci delete firewall.auto_run
    uci commit firewall
    if grep -q "${LOADER_NAME}" /etc/crontabs/root; then
        grep -v "${LOADER_NAME}" /etc/crontabs/root > /etc/crontabs/root.new
        mv /etc/crontabs/root.new /etc/crontabs/root
        /etc/init.d/cron restart
    fi
    echo -e "\033[33mauto_run has been disabled!\033[0m"
}
main() {
    case $1 in
        "")
            if [ -e "/tmp/log/auto_run.log" ]; then
                exit 0
            fi
            auto_run
            ;;
        enable) enable ;;
        disable) disable ;;
        *) echo -e "\033[31mUnknown parameter: $1\033[0m"; return 1 ;;
    esac
}
main "$@"
