#!/bin/bash

opts=$(
    {
        swaymsg -t get_tree |
            awk '/"app_id"/ { split($2,r,"\""); print "w:"r[2] }'
    } &
    {
        bt list |
            awk '{
                match($0,/https?:\/\/(www\.)?(.*)/,r)
                print "t:"$1":"r[2]
                }
            ' |
            awk -F: '
                $3 ~ /app.slack/ { print $1":"$2":slack"}
                $3 ~ /teams.microsoft.com/ { print $1":"$2":teams"}
                $3 ~ /outlook.live.com/ { print $1":"$2":outlook"}
                $3 ~ /sortedgroup.app.opsgenie/ { print $1":"$2":opsgenie"}
                { print $0 }
            '

    } &
    wait
 )

IFS=: read module ref _ <<< $(dmenu-wl <<< "$opts")

case "$module" in
    t)
        bt activate $ref
        swayr switch-to-app-or-urgent-or-lru-window -l -o -u firefox
        ;;
    w)
        swayr switch-to-app-or-urgent-or-lru-window -l -o -u $ref || $ref
        ;;
esac

