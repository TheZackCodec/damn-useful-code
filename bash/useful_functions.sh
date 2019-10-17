#!/bin/bash

##### Author ##### 
# - Name: Zachery Notz, 
# - Github: TheZackCodec
# I made all of this because i was tired of looking on online every time I forgot how to do something.
# just source this script in any bash script (Make the header is (#!/bin/bash))


##### Get general information ##### 

username=$USER
home_dir=$(getent passwd "$USER" | cut -d: -f6 )
starting_dir=$(pwd)
scripts_dir="${starting_dir%useful_scripts*}useful_scripts"


##### Permission and error checks #####

# Check if the script is running as root
is_root() {
    if [ $(id -u) -ne 0 ] ; then 
        return 0
    else
        return 1
    fi
}

# Immediately stop execution if the script is not running as root 
stop_if_not_root() {
    if [ $(id -u) -ne 0 ] ; then 
        print_text_in_color "$IRed" "This script needs to be run with sudo!"
        exit 1 
    fi
}

# Check if command exited with an error and exit if so (pass in $? which holds the exit status of the last executed code)
stop_if_error() {
    if [ $1 -ne 0 ]; then
        print_text_in_color "$IRed" "A critical part of the scrip failed please check what went wrong and rerun!"
        exit 1
    fi 
}

##### Checking if things exist #####

# Check if directory exists (pass in $(pwd)/path/to/dir to start looking from current directory)
dir_exists() {
    if [ -d "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Check if file Exists (pass in $(pwd)/path/to/dir to start looking from current directory)
file_exists() {
    if [ -f "$1" ]; then
        return 0
    else
        return 1
    fi
}


##### Installing Dependencies #####

# Check if the debian package is installed (is_this_installed_dpkg wget) "2>/dev/null" hides error output
is_this_installed_dpkg() {
    if dpkg-query -W -f='${Status}' "${1}" 2>/dev/null | grep -q "ok installed"; then
        return 0
    else
        return 1
    fi
}

# Install a program if it is not already installed
install_if_not_apt() {
    if is_this_installed_dpkg "${1}"; then
        print_text_in_color "$IGreen" "${1} is already installed."
    else
        print_text_in_color "$IYellow" "${1} is not installed" 
        sudo apt update -q4 & loading_spinner "Updating apt Repositories" "0"
        sudo apt install -q4 "${1}" -y & loading_spinner "Installing ${1}" "0"

        # Check if installation worked
        if ! is_this_installed_dpkg "${1}"; then
            print_text_in_color "$IRed" "ERROR unable to install ${1}";
            exit 1
        else
            print_text_in_color "$IGreen" "${1} Installed!" 
        fi
    fi
}

stop_if_not_installed_dpkg() {
    if is_this_installed_dpkg "${1}"; then
        print_text_in_color "$IGreen" "${1} is already installed."
    else
        print_text_in_color "$IRed" "${1} is not installed"
        echo ""
        print_text_in_color "$IRed" "${1} needs to be installed to continue!"
        print_text_in_color "$ICyan" "Please use the scripts provided to install ${1}"
        exit 1
    fi  
}

# Creates a visual loading spinner while waiting for a process
# Usage: apt update & loading_spinner "Updating apt repositories" 
loading_spinner() {
    local PID=$!
    local i=0
    while [ -d /proc/$PID ]; do
        c=`expr ${i} % 4`
        case ${c} in
            0) echo -n "\e[0K\r${1} \ " ;;
            1) echo -n "\e[0K\r${1} | " ;;
            2) echo -n "\e[0K\r${1} / " ;;
            3) echo -n "\e[0K\r${1} - " ;;
        esac
        i=`expr ${i} + 1`
        # Change the speed of the spinner by altering the 1 below
        sleep 0.1
    done
    if [ "${2}" = "0" ]; then
        echo -n "\e[0K\r"
    else
        echo -n "\e[0K\rFinished ${1}\n"
    fi
}


##### Dialog Boxes #####

# Set defaults for boxes
set_options() {
    # Interpret declarative statement as dictionary
    eval "declare -A local options="${1#*=}
    if [ -z "${options[title]}" ]; then options[title]="Default Title"; fi
    if [ -z "${options[message]}" ]; then options[message]=""; fi
    if [ -z "${options[extext]}" ]; then options[extext]="Default Example Text"; fi
    if [ -z "${options[h]}" ]; then options[h]="$WT_HEIGHT"; fi
    if [ -z "${options[w]}" ]; then options[w]="$WT_WIDTH"; fi
    # Print dictionary as declarative statement
    echo "$(declare -p options)"
}

# Displays a message to user, Keys-Used->([title], [message], [h], [w])
msg_box() {
    # Interpret declarative statement as dictionary
    eval "declare -A local in_options="${1#*=}
    # Send dictionary to set_options as declarative statement
    local options_string=$(set_options "$(declare -p in_options)")
    # Interpret declarative statement as dictionary
    eval "declare -A local options="${options_string#*=}

    # Build and display message box
    whiptail --title "${options[title]}" --msgbox "${options[message]}" "${options[h]}" "${options[w]}"
}

# Asks yes or no and returns 0(yes/true) or 1(no/false), Keys-Used->([title], [message], [h], [w])
yn_box() {
    # Interpret declarative statement as dictionary
    eval "declare -A local in_options="${1#*=}
    # Send dictionary to set_options as declarative statement
    local options_string=$(set_options "$(declare -p in_options)")
    # Interpret declarative statement as dictionary
    eval "declare -A local options="${options_string#*=}

    if (whiptail --title "${options[title]}" --yesno "${options[message]}" "${options[h]}" "${options[w]}"); then
        return 0
    else
        return 1
    fi
}

# Prompts for user input and prints it. Keys-Used->([title], [message], [extext], [h], [w])
input_box() {
    # Interpret declarative statement as dictionary
    eval "declare -A local in_options="${1#*=}
    # Send dictionary to set_options as declarative statement
    local options_string=$(set_options "$(declare -p in_options)")
    # Interpret declarative statement as dictionary
    eval "declare -A local options="${options_string#*=}
    
    echo $(whiptail --title "${options[title]}"  --inputbox "${options[message]}" "${options[h]}" "${options[w]}" "${options[extext]}" 3>&1 1>&2 2>&3)
}

# Prompts for password and prints it. Keys-Used->([title], [message], [h], [w])
pwd_box() {
    # Interpret declarative statement as dictionary
    eval "declare -A local in_options="${1#*=}
    # Send dictionary to set_options as declarative statement
    local options_string=$(set_options "$(declare -p in_options)")
    # Interpret declarative statement as dictionary
    eval "declare -A local options="${options_string#*=}

    local PASSWORD; local PASSWORD2;
    while true; do
        PASSWORD=$(whiptail --title "${options[title]}"  --passwordbox "${options[message]}" "${options[h]}" "${options[w]}" 3>&1 1>&2 2>&3)
        PASSWORD2=$(whiptail --title "Confirm Password" --passwordbox "Retype password to confirm" "${options[h]}" "${options[w]}" 3>&1 1>&2 2>&3)
        if [ -z $PASSWORD ] && [ -z $PASSWORD2 ]; then
            options[message]="The password typed was blank please retype"
        elif [ "$PASSWORD" = "$PASSWORD2" ]; then
            break
        else 
            options[message]="The passwords typed were not the same. Please try again"
        fi
    done

    echo $PASSWORD
}

# (still not fully working) Prompts for password and prints it. Keys-Used->([title], [message], [h], [w])
menu_box() {
    # Interpret declarative statement as dictionary
    eval "declare -A local in_options="${1#*=}
    # Send dictionary to set_options as declarative statement
    local options_string=$(set_options "$(declare -p in_options)")
    # Interpret declarative statement as dictionary
    eval "declare -A local options="${options_string#*=}

    whiptail --title "${options[title]}" --menu "${options[message]}" 25 78 16 \
    "<-- Back" "Return to the main menu." \
    "Add User" "Add a user to the system." \
    "Modify User" "Modify an existing user." \
    "List Users" "List all users on the system." \
    "Add Group" "Add a user group to the system." \
    "Modify Group" "Modify a group and its list of members." \
    "List Groups" "List all groups on the system." \
    3>&1 1>&2 2>&3
}

# (still not fully working) Prompts for password and prints it. Keys-Used->([title], [message], [h], [w])
chk_lst () {
    # Interpret declarative statement as dictionary
    eval "declare -A local in_options="${1#*=}
    # Send dictionary to set_options as declarative statement
    local options_string=$(set_options "$(declare -p in_options)")
    # Interpret declarative statement as dictionary
    eval "declare -A local options="${options_string#*=}

    whiptail --title "${options[title]}" --checklist "${options[message]}" 20 78 4 \
    "NET_OUTBOUND" "Allow connections to other hosts" ON \
    "NET_INBOUND" "Allow connections from other hosts" OFF \
    "LOCAL_MOUNT" "Allow mounting of local devices" OFF \
    "REMOTE_MOUNT" "Allow mounting of remote devices" OFF \
    3>&1 1>&2 2>&3
}

# (still not fully working) Prompts for password and prints it. Keys-Used->([title], [message], [h], [w])
r_lst () {
    # Interpret declarative statement as dictionary
    eval "declare -A local in_options="${1#*=}
    # Send dictionary to set_options as declarative statement
    local options_string=$(set_options "$(declare -p in_options)")
    # Interpret declarative statement as dictionary
    eval "declare -A local options="${options_string#*=}

    whiptail --title "${options[title]}" --radiolist "${options[message]}" 20 78 4 \
    "NET_OUTBOUND" "Allow connections to other hosts" ON \
    "NET_INBOUND" "Allow connections from other hosts" OFF \
    "LOCAL_MOUNT" "Allow mounting of local devices" OFF \
    "REMOTE_MOUNT" "Allow mounting of remote devices" OFF \
    3>&1 1>&2 2>&3
}

# (I honestly still do not know how to use this one correctly) Keys-Used->([title], [message], [h], [w])
p_bar (){
    whiptail --gauge "${options[message]}" 6 50 $1
}


##### Nice Color Output #####

# Helps create colorful output (Use any color defined below or make your own)
print_text_in_color() {
	printf "%b%s%b\n" "$1" "$2" "$Color_Off"
}

##### bash colors #####

# Reset
Color_Off='\e[0m'       # Text Reset

# Regular Colors
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Yellow='\e[0;33m'       # Yellow
Blue='\e[0;34m'         # Blue
Purple='\e[0;35m'       # Purple
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White

# Bold
BBlack='\e[1;30m'       # Black
BRed='\e[1;31m'         # Red
BGreen='\e[1;32m'       # Green
BYellow='\e[1;33m'      # Yellow
BBlue='\e[1;34m'        # Blue
BPurple='\e[1;35m'      # Purple
BCyan='\e[1;36m'        # Cyan
BWhite='\e[1;37m'       # White

# Underline
UBlack='\e[4;30m'       # Black
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
UYellow='\e[4;33m'      # Yellow
UBlue='\e[4;34m'        # Blue
UPurple='\e[4;35m'      # Purple
UCyan='\e[4;36m'        # Cyan
UWhite='\e[4;37m'       # White

# Background
On_Black='\e[40m'       # Black
On_Red='\e[41m'         # Red
On_Green='\e[42m'       # Green
On_Yellow='\e[43m'      # Yellow
On_Blue='\e[44m'        # Blue
On_Purple='\e[45m'      # Purple
On_Cyan='\e[46m'        # Cyan
On_White='\e[47m'       # White

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White

# Bold High Intensity
BIBlack='\e[1;90m'      # Black
BIRed='\e[1;91m'        # Red
BIGreen='\e[1;92m'      # Green
BIYellow='\e[1;93m'     # Yellow
BIBlue='\e[1;94m'       # Blue
BIPurple='\e[1;95m'     # Purple
BICyan='\e[1;96m'       # Cyan
BIWhite='\e[1;97m'      # White

# High Intensity backgrounds
On_IBlack='\e[0;100m'   # Black
On_IRed='\e[0;101m'     # Red
On_IGreen='\e[0;102m'   # Green
On_IYellow='\e[0;103m'  # Yellow
On_IBlue='\e[0;104m'    # Blue
On_IPurple='\e[0;105m'  # Purple
On_ICyan='\e[0;106m'    # Cyan
On_IWhite='\e[0;107m'   # White