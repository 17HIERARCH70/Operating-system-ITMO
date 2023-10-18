#!/bin/bash

BLOCK=""
BASEDIR="/tmp"
LOGFILE="io_scheduler_tests.log"

I_B() {
    echo "Информация о планировщике ввода-вывода"
    iostat -p
    echo "Текущий планировщик ввода-вывода:"
    cat /sys/block/$BLOCK/queue/scheduler
    echo "Информация о диске"
    lsblk -l
}

T_S() {
    echo "Тестирование планировщиков ввода-вывода"
    wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.13.7.tar.xz -P $BASEDIR

    for T in none mq-deadline kyber bfq; do
        rm -rf $BASEDIR/linux-3.13.7
        rm $BASEDIR/benchfile

        echo 3 > /proc/sys/vm/drop_caches
        echo "Планировщик -> $T"
        echo "Информация о диске"
        iostat -p

        echo "Тестирование Bonnie++"
        mkdir $BASEDIR/boniee_test_dir
        bonnie++ -u root -d $BASEDIR/boniee_test_dir
        rm -rf $BASEDIR/boniee_test_dir
        echo 3 > /proc/sys/vm/drop_caches

        echo "Тестирование FIO"
        sudo fio --filename=$BASEDIR/path --size=1GB --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=10 --numjobs=4 --time_based --group_reporting --name=job_name --eta-newline=1

        echo 3 > /proc/sys/vm/drop_caches

        echo "Тестирование HDPARM"
        echo $T > /sys/block/$BLOCK/queue/scheduler
        cat /sys/block/$BLOCK/queue/scheduler
        sync && /sbin/hdparm -tT /dev/$BLOCK
        echo "----"
        echo 3 > /proc/sys/vm/drop_caches

        echo "Тестирование DD"
        for i in 1 2 3 4 5; do
            time dd if=$BASEDIR/path of=./benchfile bs=1M count=19900 conv=fdatasync,notrunc
            echo 3 > /proc/sys/vm/drop_caches
        done

        echo "Тестирование TAR"
        for i in 1 2 3 4 5; do
            time tar xJf $BASEDIR/linux-3.13.7.tar.xz
            echo 3 > /proc/sys/vm/drop_caches
        done
    done
    rm $BASEDIR/path
    rm -rf $BASEDIR/linux-3.13.7
    rm $BASEDIR/benchfile
    rm $BASEDIR/linux-3.13.7.tar.xz
}

find_best_scheduler() {
    echo "По результатам тестирования наилучший планировщик ввода-вывода:"
    best_scheduler=$(cat $LOGFILE | grep "Тестирование HDPARM" | sed -n -e '/Планировщик ->/!{p;d;};N;s/\(Планировщик ->\)\(.*\)\(\nИнформация о диске\)\(.*\)\(\nТестирование HDPARM\)\(.*\)\(\n\)/\2/p')
    echo "$best_scheduler"
}

main() {
    clear
    echo "Выберите диск с доступными планировщиками ввода-вывода"
    lsblk -l
    read -p "Введите имя диска (sda/sdb/..): " BLOCK
    clear

    while true; do
        echo "Меню планировщиков ввода-вывода"
        echo "Выберите опцию:"
        echo "1. Просмотр системной информации"
        echo "2. Начать тестирование планировщиков ввода-вывода"
        echo "3. Найти наилучший планировщик"
        echo "4. Выход"

        read -p "Введите 1-4: " choice

        case $choice in
            1) clear; I_B ;;
            2) clear; T_S ;;
            3) clear; find_best_scheduler ;;
            4) exit ;;
            *) echo "Неверная опция, выберите допустимую опцию." ;;
        esac
    done
}

main
