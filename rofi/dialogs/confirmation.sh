
dir="$HOME/.config/rofi/dialogs"
theme='style-5'

yes=''
no=''
# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-p 'Confirmation' \
		-mesg 'Logoff initiated. Time to touch some grass.' \
		-theme ${dir}/${theme}.rasi
}

# Ask for confirmation
confirm_exit() {
	echo -e "$yes\n$no" | confirm_cmd
}

# Pass variables to rofi dmenu
run_rofi() {
	echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
    if [[ "$selected" == "$yes" ]]; then
        if [[ "$DESKTOP_SESSION" == 'openbox' ]]; then
            openbox --exit
        elif [[ "$DESKTOP_SESSION" == 'bspwm' ]]; then
            bspc quit
        elif [[ "$DESKTOP_SESSION" == 'i3' ]]; then
            i3-msg exit
        elif [[ "$DESKTOP_SESSION" == 'plasma' ]]; then
            qdbus org.kde.ksmserver /KSMServer logout 0 0 0
        elif [[ "$DESKTOP_SESSION" == 'hyprland' ]]; then
            hyprctl dispatch exit
        fi
    else
        exit 0
    fi
}


run_cmd --logout

