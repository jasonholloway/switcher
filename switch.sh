#!/bin/bash

tree=$(swaymsg -t get_tree)

opts=$(
    {
        awk '/"app_id"/ { split($2,r,"\""); print "a:"r[2]":"tolower(r[2]) }' <<< "$tree"
    } &
    {
        bt list |
            awk '{
                    FS=" "; OFS=":"
                    ref=$1
                    match($0,/https?:\/\/(www\.)?(.*)/,r)
                    
                    $0=""
                    $1="w"
                    $2=ref
                    $3=substr(tolower(r[2]),0,50)
                    full=$0
                }
                $3 ~ /app.slack/ { $3="slack" }
                $3 ~ /teams.microsoft.com/ { $3="teams" }
                $3 ~ /outlook.(live|office).com/ { $3="outlook" }
                $3 ~ /sortedgroup.app.opsgenie/ { $3="opsgenie" }
                $3 ~ /sortedproapp.visualstudio.com/ { $3="azdo" }
                $3 ~ /app.datadoghq.com/ { $3="datadog" }
                { print; print full } 
            '

    } &
    {
        windows=$(tmux list-windows -F '#{window_id} #{session_id} #{window_name}')

        tmux list-clients -F '#{client_pid} #{session_id}' |
            while read pid sid _
            do
                awk '
                    $2 == "'$sid'" && $3 != "-" {
                        print "t:'$pid'."$1":"tolower($3)
                    }
                    ' <<< "$windows"
            done
    }
    wait
 )

IFS=: read module ref _ <<< $(dmenu-wl <<< "$opts")

case "$module" in
    a)
        swaymsg "[app_id=$ref] focus" || $ref
        ;;
    w)
        bt activate $ref

        IFS='.' read clientId windowId tabId _ <<< "$ref"

        read _ url pid name _ <<< $(bt clients | awk "/^$clientId\./")

        case "$name" in
            firefox) swaymsg "[app_id=firefox] focus";;
            *chromium) swaymsg "[app_id=chromium-bin-browser-chromium] focus";;
        esac
        ;;
    t)
        IFS='.' read pid wid _ <<< "$ref"

        while read p _
        do
            if [[ $p != 1 ]]
            then
                if swaymsg "[pid=$p] focus" 
                then
                    tmux select-window -t $wid
                    break
                fi
            fi
        done <<< $(pstree -paAsT $pid | cut -d',' -f2)
        ;;
esac

