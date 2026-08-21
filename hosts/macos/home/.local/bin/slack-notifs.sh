#!/usr/bin/env bash
STATUS_LABEL=$(lsappinfo info -only StatusLabel "Slack")

if [[ $STATUS_LABEL =~ \"label\"=\"([^\"]*)\" ]]; then
    LABEL="${BASH_REMATCH[1]}"

    if [[ -z "$LABEL" ]]; then
        echo "0"
    elif [[ "$LABEL" == "•" ]]; then
        echo "$LABEL"
    elif [[ "$LABEL" =~ ^[0-9]+$ ]]; then
        echo "$LABEL"
    else
        echo "0"
    fi
else
    echo "0"
fi
