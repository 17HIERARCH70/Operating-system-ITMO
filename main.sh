#!/bin/bash

os=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
work_dir=$PWD

Require() {
	case $os in
		debian|ubuntu)
		packages=(
			["hdparm"]="hdparm"
			["sysstat"]="sysstat"
			["tmux"]="tmux"
			["iptables"]="iptables"
			["nasm"]="nasm"
            ["gcc"]="gcc"
            ["make"]="make"
            ["zfsutils-linux"] ="zfsutils-linux"
            ["btrfs-progs"] ="btrfs-progs"
            ["fio"] ="fio"
            ["xfsprogs"] ="xfsprogs"
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
            ["zfsutils-linux"] ="zfsutils-linux"
			["hdparm"]="hdparm"
            ["gcc"]="gcc"
			["sysstat"]="sysstat"
			["tmux"]="tmux"
			["iptables"]="iptables"
			["nasm"]="nasm"
            ["btrfs-progs"] ="btrfs-progs"
            ["xfsprogs"] ="xfsprogs"
            ["fio"] ="fio"
            ["duperemove"] ="duperemove"
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

FSchecker() {
    # Установка необходимых утилит
    sudo apt update
    
    sudo apt install -y fio btrfs-progs zfsutils-linux

    # Создание временных файлов и разделов для тестирования
    declare -A images=(
        ["btrfs"]="/tmp/btrfs.img"
        ["zfs"]="/tmp/zfs.img"
        ["xfs"]="/tmp/xfs.img"
        ["ext4"]="/tmp/ext4.img"
    )

    for img in "${images[@]}"; do
        dd if=/dev/zero of=$img bs=1M count=1024
    done

    # Форматирование образов в выбранные ФС
    sudo mkfs.btrfs ${images["btrfs"]}
    sudo mkfs.xfs ${images["xfs"]}
    sudo mkfs.ext4 ${images["ext4"]}

    # Подключение файловых систем
    mkdir -p /mnt/{btrfs,zfs,xfs,ext4}
    sudo mount -o loop ${images["btrfs"]} /mnt/btrfs
    sudo mount -o loop ${images["xfs"]} /mnt/xfs
    sudo mount -o loop ${images["ext4"]} /mnt/ext4
    sudo zpool create testpool ${images["zfs"]}
    sudo zfs set mountpoint=/mnt/zfs testpool

    # Ассоциативный массив для хранения результатов
    declare -A results

    # Тестирование с помощью fio и запись результатов
    logfile="fs_test_results.log"
    echo "FS Test Results" > $logfile
    for fs in "${!images[@]}"; do
        echo "Testing $fs..."
        result=$(sudo fio --randrepeat=1 --ioengine=libaio --direct=1 --gtod_reduce=1 --name=test --filename=/mnt/$fs/testfile --bs=4k --iodepth=64 --size=4G --readwrite=randrw --rwmixread=75 | grep -E "read: IOPS=|write: IOPS=")
        read_iops=$(echo $result | grep -oP 'read: IOPS=\K\d+')
        write_iops=$(echo $result | grep -oP 'write: IOPS=\K\d+')
        results[$fs]=$((read_iops + write_iops))
        echo "$fs Read IOPS: $read_iops, Write IOPS: $write_iops" | tee -a $logfile
    done

    # Определение лучшей ФС
    best_fs=""
    best_score=0
    for fs in "${!results[@]}"; do
        if [[ ${results[$fs]} -gt $best_score ]]; then
            best_score=${results[$fs]}
            best_fs=$fs
        fi
    done

    echo "Best FS based on IOPS: $best_fs" | tee -a $logfile

    # Отключение ФС и очистка
    sudo umount /mnt/btrfs
    sudo umount /mnt/xfs
    sudo umount /mnt/ext4
    sudo zpool destroy testpool
    for img in "${images[@]}"; do
        rm -rf $img
    done

    cd $workdir
}

Scheduler() {
    DISC="sda"
    ORIG_SCHEDULER=$(cat /sys/block/$DISC/queue/scheduler | grep -o '[[]\w*[]]' | tr -d '[]')
    echo "Текущий планировщик для $DISC: $ORIG_SCHEDULER"
    echo "----"

    BEST_SCHEDULER=""
    BEST_SPEED=0

    for T in noop deadline cfq; do
        # Устанавливаем планировщик и проверяем успешность выполнения
        if echo $T > /sys/block/$DISC/queue/scheduler 2>/dev/null; then
            # Выводим установленный планировщик
            echo "Установлен планировщик $T для $DISC:"
            # Выполняем тесты на диске
            RESULT=$(sync && /sbin/hdparm -tT /dev/$DISC | grep "Timing buffered disk reads")
            SPEED=$(echo $RESULT | cut -d "=" -f 2 | cut -d " " -f 2)
            echo "$RESULT"
            echo "----"
            # Сравниваем скорости для выбора лучшего планировщика
            if (( $(echo "$SPEED > $BEST_SPEED" | bc -l) )); then
                BEST_SPEED=$SPEED
                BEST_SCHEDULER=$T
            fi
        else
            echo "Не удалось установить планировщик $T для $DISC"
            echo "----"
        fi
    done

    # Выводим лучший планировщик
    echo "Лучший планировщик для $DISC: $BEST_SCHEDULER с скоростью $BEST"
    cd $workdir
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
	BASEDIR=$(dirname "$(realpath "$0")")    

    echo "Выбери подпрограмму:"
    echo "1 - ForkBomb"
    echo "2 - MemBomb"
    echo "3 - LinPack"
    echo "4 - Scheduler"
    echo "5 - FSchecker"
    echo "Для выхода нажми - 6"

	read -p "Введи 1-6: " Lab
	case $Lab in
		1) clear; ForkBomb ;;
        2) clear; MemBomb ;;
        3) clear; LinPack ;;
        4) clear; Scheduler;;
        5) clear; FSchecker;;
		6) clear; exit;;
	esac
	main
}

Require;
clear; cd $work_dir; main;