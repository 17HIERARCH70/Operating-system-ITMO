#!/bin/bash

os=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
work_dir=$PWD

install_programs() 
{
	case $os in
		debian|ubuntu)
		packages=(
			["hdparm"]="hdparm"
			["bonnie++"]="bonnie++"
			["sysstat"]="sysstat"
			["fio"]="fio"
			["lolcat"]="lolcat"
			["figlet"]="figlet"
			["xcowsay"]="xcowsay"
			["cowsay"]="cowsay"
			["fortune"]="fortune"
			["boxes"]="boxes"
			["tmux"]="tmux"
			["libpam0g-dev"]="libpam0g-dev"
			["libnfnetlink"]="libnfnetlink"
			["libnfnetlink-dev"]="libnfnetlink-dev"
			["libnetfilter-queue-dev"]="libnetfilter-queue-dev"
			["iptables"]="iptables"
			["pam-utils"]="pam-utils"
			["pam"]="pam"
			["nasm"]="nasm"
			["base-devel"]="base-devel"
			["base-devel"]="net-tools"
            ["gcc"]="gcc"
			
		)
		for package in "${!packages[@]}"; do
			if ! dpkg -s "${packages[$package]}" > /dev/null 2>&1; then
				sudo apt-get install -y "${packages[$package]}"
				
			else
				echo "$package уже установлен."
			fi
		done
		sudo apt install boxes
		;;
		
		arch)
		declare -A packages=(
			["hdparm"]="hdparm"
            ["gcc"]="gcc"
			["bonnie++"]="bonnie++"
			["sysstat"]="sysstat"
			["fio"]="fio"
			["lolcat"]="lolcat"
			["figlet"]="figlet"
			["xcowsay"]="xcowsay"
			["cowsay"]="cowsay"
			["fortune"]="fortune"
			["cowfortune"]="cowfortune"
			["boxes"]="boxes"
			["tmux"]="tmux"
			["libpam0g-dev"]="libpam0g-dev"
			["libnfnetlink"]="libnfnetlink"
			["libnfnetlink-dev"]="libnfnetlink-dev"
			["libnetfilter-queue-dev"]="libnetfilter-queue-dev"
			["iptables"]="iptables"
			["nasm"]="nasm"
			["pam-utils"]="pam-utils"
			["pam"]="pam"
			["base-devel"]="base-devel"
			["inetutils"]="inetutils"
		)
		for package in "${!packages[@]}"; do
			if ! pacman -Qs "${packages[$package]}" > /dev/null 2>&1; then
				sudo pacman -S "${packages[$package]}"
			else
				echo "$package уже установлен."
			fi
		done
		
		if ! pacman -Qs yaourt > /dev/null 2>&1; then
			current_user=$(logname)
			sudo pacman -S --needed base-devel git wget yajl
			cd /tmp
			git clone https://aur.archlinux.org/package-query.git
			cd package-query/
			makepkg -si && cd /tmp/
			git clone https://aur.archlinux.org/yaourt.git
			cd yaourt/
			
			makepkg -si

		else
			echo "yaourt уже установлен."
		fi
		
		for package in "${!packages[@]}"; do
			if ! yaourt -Q "${packages[$package]}" > /dev/null 2>&1; then
				yaourt -S "${packages[$package]}"
			else
				echo "$package уже установлен."
			fi
		done
		
		sleep 20
		;;
		*)
		echo "Не удалось определить менеджер пакетов для этой операционной системы."
		exit 1
		;;
	esac
}

remove_programs() 
{
	case $os in
		debian|ubuntu)
		packages=(
			["hdparm"]="hdparm"
			["bonnie++"]="bonnie++"
			["sysstat"]="sysstat"
			["fio"]="fio"
			["lolcat"]="lolcat"
			["figlet"]="figlet"
			["xcowsay"]="xcowsay"
			["cowsay"]="cowsay"
			["fortune"]="fortune"
			["boxes"]="boxes"
			["tmux"]="tmux"
			["nasm"]="nasm"
			["libpam0g-dev"]="libpam0g-dev"
			["libnfnetlink"]="libnfnetlink"
			["libnfnetlink-dev"]="libnfnetlink-dev"
			["libnetfilter-queue-dev"]="libnetfilter-queue-dev"
			["iptables"]="iptables"
			["pam-utils"]="pam-utils"
			["pam"]="pam"
			["base-devel"]="base-devel"
		)
		for package in "${!packages[@]}"; do
			sudo apt-get delete -y "${packages[$package]}"
		done
		;;
		arch)
		declare -A packages=(
			["hdparm"]="hdparm"
			["bonnie++"]="bonnie++"
			["sysstat"]="sysstat"
			["fio"]="fio"
			["lolcat"]="lolcat"
			["figlet"]="figlet"
			["xcowsay"]="xcowsay"
			["cowsay"]="cowsay"
			["fortune"]="fortune"
			["boxes"]="boxes"
			["tmux"]="tmux"
			["nasm"]="nasm"
			["libpam0g-dev"]="libpam0g-dev"
			["libnfnetlink"]="libnfnetlink"
			["libnfnetlink-dev"]="libnfnetlink-dev"
			["libnetfilter-queue-dev"]="libnetfilter-queue-dev"
			["iptables"]="iptables"
			["pam-utils"]="pam-utils"
			["pam"]="pam"
			["base-devel"]="base-devel"
		)
		for package in "${!packages[@]}"; do
			sudo pacman -R "${packages[$package]}"
		done
		
		for package in "${!packages[@]}"; do
				yaourt -R "${packages[$package]}"
		done
		
		sudo pacman -R --needed base-devel git wget yajl
		sudo rm -rf /tmp/package-query
		sudo pacman -R yaourt
		current_user=$(logname)
		sudo -u "$current_user" yaourt -R boxes
		;;
		*)
		echo "Не удалось определить менеджер пакетов для этой операционной системы."
		exit 1
		;;
	esac
	main
}

ForkBomb() {
    echo "ForkBomb" 

    cd "$BASEDIR/ForkBomb"

    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin" ]]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            gcc -o main ForkbombLin.c
        else
            gcc -o main ForkbombWin.c
        fi

        read -p "Вы уверены?
        Нажми, чтобы принять - 'y', отклонить - 'n': " response

        if [ "$response" == "y" ]; then
            echo "Запуск..."
            sleep 2
            ./main
        elif [ "$response" == "n" ]; then
            echo "Отменяем запуск..."
        else
            echo "Некорректный ввод"
        fi

        read -p "Вы хотите удалить скомпилируемые файлы?(y/n): " response

        if [ "$response" == "y" ]; then
            find . -iname "main*" -delete
        elif [ "$response" == "n" ]; then
            echo "Отменяем удаление"
        else
            echo "Некорректный ввод"
        fi

        cd "$BASEDIR"
        main
    else
        echo "Не поддерживается ОС: $OSTYPE"
    fi
}


main() 
{
	BASEDIR=$(dirname "$(realpath "$0")")    
    echo "Выбери подпрограмму:"
    echo "1 - ForkBomb"
    echo "2 - MemBomb"
    echo "3 - LimPack"
    echo "Для выхода нажми - 4"

	read -p "Введи 1-14: " S_Modules
	case $S_Modules in
		1) clear; ForkBomb ;;
        2) clear; MemBomb ;;
        3) clear; LimPack ;;
		4) clear; exit;;
	esac
	main
}

install_programs;
clear; cd $work_dir; main;