

#!/data/data/com.termux/files/usr/bin/bash

# Cores
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
NC='\033[0m'

LOGFILE="$HOME/bloatlog.txt"
> "$LOGFILE"

log() {
    echo "$@" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOGFILE"
    echo -e "$@"
}


DISABLE_LIST=(
    "com.google.android.apps.work.clouddpc"
    "com.google.android.apps.nbu.files"
    "com.google.android.gm"
    "com.google.android.as"
    "com.google.android.apps.safetyhub"
    "com.google.audio.hearing.visualization.accessibility.scribe"
    "com.google.android.setupwizard"
)

DISABLE_COMPONENTS=(
    "com.google.android.gms/.backup.component.BackupOrRestoreSettingsActivity"
)

UNINSTALL_LIST=(
    "com.google.android.projection.gearhead"
    "com.google.android.apps.wellbeing"
    "com.google.android.apps.turbo"
    "com.google.android.accessibility.switchaccess"
)

process_package() {
    local pkg="$1"
    local action="$2"
    local cmd="$3"
    
    [ -z "$pkg" ] && return
    ((total++))
    
    if ! su -c "pm list packages" | grep -qw "$pkg"; then
        ((notfound++))
        log "${Y}NOT FOUND: $pkg${NC}"
        return
    fi
    
    output=$(su -c "$cmd $pkg" 2>&1)
    
    if echo "$output" | grep -qiE "success|disabled"; then
        if [ "$action" = "disable" ]; then
            ((disabled++))
            log "${G}DISABLED: $pkg${NC}"
        else
            ((uninstalled++))
            log "${G}UNINSTALLED: $pkg${NC}"
        fi
    else
        ((failed++))
        log "${R}FAILED: $pkg${NC}"
    fi
}

process_component() {
    local comp="$1"
    
    [ -z "$comp" ] && return
    ((total++))
    
    output=$(su -c "pm disable $comp" 2>&1)
    
    if echo "$output" | grep -qiE "success|disabled|new state: disabled"; then
        ((disabled++))
        log "${G}DISABLED COMPONENT: $comp${NC}"
    else
        ((failed++))
        log "${R}FAILED: $comp${NC}"
    fi
}

log "${C}Starting script...${NC}\n"

if [ ${#DISABLE_LIST[@]} -gt 0 ]; then
    log "${C}Disabling ${#DISABLE_LIST[@]} packages...${NC}\n"
    for pkg in "${DISABLE_LIST[@]}"; do
        process_package "$pkg" "disable" "pm disable"
    done
fi

if [ ${#DISABLE_COMPONENTS[@]} -gt 0 ]; then
    log "\n${C}Disabling ${#DISABLE_COMPONENTS[@]} components...${NC}\n"
    for comp in "${DISABLE_COMPONENTS[@]}"; do
        process_component "$comp"
    done
fi

if [ ${#UNINSTALL_LIST[@]} -gt 0 ]; then
    log "\n${C}Uninstalling ${#UNINSTALL_LIST[@]} packages...${NC}\n"
    for pkg in "${UNINSTALL_LIST[@]}"; do
        process_package "$pkg" "uninstall" "pm uninstall --user 0"
    done
fi

log "\n${C}Completed! Log saved at: $LOGFILE${NC}\n"
