#!/bin/zsh

run_command() {
    command="$1"
    echo "Running: $command"
    eval "$command" &
    pid=$!
    while ps -p $pid > /dev/null; do
        sleep 1
    done
}

up() {
    run_command "brew upgrade" && run_command "brew upgrade --cask --greedy" & run_command "mise up"
    run_command "mas upgrade"
    run_command "rustup update" && run_command "cargo install-update -a"
}
