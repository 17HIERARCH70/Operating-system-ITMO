#!/bin/bash

os=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
work_dir=$PWD

install_programs() {
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

remove_programs() {
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

LinPack() {
    cd LinPack
    git clone https://github.com/ereyes01/linpack.git
    cd linpack && make

    restore_default() {
        local param_name="$1"
        local default_value="$2"
        echo "$default_value" > "/proc/sys/kernel/sched_$param_name"
    }

    cd /proc/sys/kernel/
    for file in sched_*; do
        param_name="${file#sched_}"
        current_value=$(cat "$file")
        echo "sched_$param_name: $current_value"
    done

    param_list=$(ls sched_* | sed 's/sched_//')
    echo "Введите имя параметра для изменения (или 'q' для выхода) без 'sched_':"
    read -p "" chosen_param

    while [[ "$chosen_param" != "q" ]]; do
        if [[ "$param_list" =~ (^|[[:space:]])"$chosen_param"($|[[:space:]]) ]]; then
            current_value=$(cat "sched_$chosen_param")
            echo "Текущее значение '$chosen_param': $current_value. Введите новое значение:" 
            read -p "" new_value
            echo "$new_value" > "sched_$chosen_param"
            echo "Значение параметра '$chosen_param' изменено на '$new_value'."
        else
            echo "Неверное имя параметра. Попробуйте еще раз."
        fi

        echo "Введите имя параметра для изменения (или 'q' для выхода):"
        read -p "" chosen_param
    done

    echo "Вы хотите восстановить значения по умолчанию? (y/n):"
    read -p "" restore_default_choice

    if [[ "$restore_default_choice" == "y" ]]; then
        for param in $param_list; do
            default_value=$(cat "sched_$param")
            restore_default "$param" "$default_value"
            echo "Значение параметра '$param' восстановлено по умолчанию: $default_value"
        done
    fi

    cd $BASEDIR
    cd linpack

    for ((i=1; i<=2; i++)); do
        ./linpack
    done

    for ((i=1; i<=2; i++)); do
        nice -n -19 ./linpack
    done

    for ((i=1; i<=2; i++)); do
        nice -n 20 ./linpack
    done

    for ((i=1; i<=2; i++)); do
        taskset -c 0 ./linpack
        taskset -c 1,2 ./linpack
    done

    for ((i=1; i<=2; i++)); do
        ./linpack
    done

    read -p "Тестирование завершено. Проверьте результаты в './logs'. Нажмите Enter, чтобы удалить все тестовые файлы и очистить консоль."
    rm -rf $BASEDIR/linpack
    cd $workdir
}


MemBomb() {
	cd $work_dir/MemBomb/
	
    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin" ]]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            gcc -o main MemBombLin.c
        else
            gcc -o main MemBombWin.c
        fi
        
        read -p "У вас есть возможность запустить программу. 
        Будьте осторожны, это может крашнуть вашу ОС. 
        В качестве альтернативы вы можете отказаться от запуска программы. 
        Запуск - 'y', отказ от запуска - 'n': " response
        if [ "$response" == "y" ]; then
            echo "Запуск..."
            sudo ./main
        elif [ "$response" == "n" ]; then
            echo "Отменяем запуск..."
        else
            echo "Некорректный ввод"
        fi
        
        read -p "Вы хотите удалить скомпилируемые файлы?(y/n): 	" response
        if [ "$response" == "y" ]; then
            find . -iname "main" -delete
        elif [ "$response" == "n" ]; then
            echo "Отменяем запуск..."
        else
            echo "Некорректный ввод"
        fi
     else
        echo "Не поддерживается ОС: $OSTYPE"
    fi

	cd $work_dir
	clear;main
}

ForkBomb() {

    cd "$BASEDIR/ForkBomb"

    if [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin" ]]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            gcc -o main ForkBombLin.c
        else
            gcc -o main ForkBombWin.c
        fi

        read -p "У вас есть возможность запустить программу. 
        Будьте осторожны, это может крашнуть вашу ОС. 
        В качестве альтернативы вы можете отказаться от запуска программы. 
        Запуск - 'y', отказ от запуска - 'n': " response

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

    cd $work_dir
	clear;main
}




main() {
    echo "Current directory: $PWD"
	BASEDIR=$(dirname "$(realpath "$0")")    
    echo "Current directory: $BASEDIR"
    echo "Выбери подпрограмму:"
    echo "1 - ForkBomb"
    echo "2 - MemBomb"
    echo "3 - LinPack"
    echo "Для выхода нажми - 4"

	read -p "Введи 1-14: " S_Modules
	case $S_Modules in
		1) clear; ForkBomb ;;
        2) clear; MemBomb ;;
        3) clear; LinPack ;;
		4) clear; exit;;
	esac
	main
}

install_programs;
clear; cd $work_dir; main;