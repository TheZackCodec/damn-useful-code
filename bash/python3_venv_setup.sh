#!/bin/bash


##### bash colors #####

# Reset
Color_Off='\e[0m'       # Text Reset

# High Intensity
IBlack='\e[0;90m'       # Black
IRed='\e[0;91m'         # Red
IGreen='\e[0;92m'       # Green
IYellow='\e[0;93m'      # Yellow
IBlue='\e[0;94m'        # Blue
IPurple='\e[0;95m'      # Purple
ICyan='\e[0;96m'        # Cyan
IWhite='\e[0;97m'       # White


##### Functions #####

# Check if file Exists
file_exists() {
    if [ -f "$1" ]; then
        return 0
    else
        return 1
    fi
}

# Check if command exited with an error and exit if so
stop_if_error() {
    if [ $1 -ne 0 ]; then
        print_text_in_color "$IRed" "A critical part of the scrip failed please check what went wrong and rerun!"
        exit 1
    fi 
}

# Check if debian package is installed (dpkg_is_this_installed wget) "2>/dev/null" hides error output
dpkg_is_this_installed() {
    if dpkg-query -W -f='${Status}' "${1}" 2>/dev/null | grep -q "ok installed"; then
        return 0
    else
        return 1
    fi
}

# Install a program if it is not already installed
apt_install_if_not() {
    if dpkg_is_this_installed "${1}"; then
        print_text_in_color "$IGreen" "${1} is already installed."
    else
        print_text_in_color "$IYellow" "${1} is not installed" 
        sudo apt update -q4 & loading_spinner "Updating apt Repositories" "0"
        sudo apt install -q4 "${1}" -y & loading_spinner "Installing ${1}" "0"
        stop_if_error $?
        print_text_in_color "$IGreen" "${1} Installed!" 
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

# Prints text in color
print_text_in_color() {
	printf "%b%s%b\n" "$1" "$2" "$Color_Off"
}

# Installs script dependencies
install_dependencies() {
    print_text_in_color "$IPurple" "Checking Dependencies"
    apt_install_if_not python3
    apt_install_if_not python3-venv
    echo ""
}

# Creates a python3 virtual environment
create_venv(){
    if python3 -m venv env; then
        print_text_in_color "$IGreen" "Created virtual environment folder"
    else
        print_text_in_color "$IRed" "Failed to create a virtual environment folder!"
        exit 1
    fi 
}

# Creates an activate script for less key presses
create_symbolic_link() {
    if file_exists $(pwd)/activate; then
        rm activate
    fi
    print_text_in_color "$IGreen" "Created symbolic link to activate script"
    ln -s env/bin/activate activate
}

install_python_requirements() {
    if file_exists $(pwd)/requirements.txt; then
        source env/bin/activate
        print_text_in_color "$IPurple" "Installing project requirements"
        pip install -r requirements.txt 
    else
        print_text_in_color "$IYellow" "No requirements.txt found skipping requirement installation."  
    fi
}

main() {
    print_text_in_color "$ICyan" "Starting Script"
    install_dependencies

    print_text_in_color "$ICyan" "Setting up virtual environment"
    create_venv
    create_symbolic_link
    install_python_requirements
    echo ""
    print_text_in_color "$IGreen" "Python virtual environment successfully setup!"
    print_text_in_color "$ICyan" "Note: use \"source activate\" to use environment."
}

main