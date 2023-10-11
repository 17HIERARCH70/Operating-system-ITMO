#!/bin/bash

BLOCK=""
BASEDIR="/tmp"
LOG_FILE="/tmp/io_scheduler_tests.log"

I_B() {
    echo "Информация о планировщике ввода-вывода"
    iostat -p
    echo "Текущий планировщик ввода-вывода:"
    cat /sys/block/$BLOCK/queue/scheduler
    echo "Информация о диске"
    lsblk -l
}

run_io_tests() {
    scheduler_name="$1"
    echo "Планировщик ---> $scheduler_name" >> $LOG_FILE

    echo "Информация о вводе-выводе" >> $LOG_FILE
    iostat -p >> $LOG_FILE

    echo "Тест с Bonnie" >> $LOG_FILE
    mkdir $BASEDIR/boniee_test_dir
    bonnie++ -u root -d $BASEDIR/boniee_test_dir >> $LOG_FILE
    rm -rf $BASEDIR/boniee_test_dir

    echo "Тест FIO. Случайное чтение/запись" >> $LOG_FILE
    sudo fio --filename=$BASEDIR/path --size=1GB --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=10 --numjobs=4 --time_based --group_reporting --name=job_name --eta-newline=1 >> $LOG_FILE

    echo "Тест HDPARM" >> $LOG_FILE
    echo $scheduler_name > /sys/block/$BLOCK/queue/scheduler
    cat /sys/block/$BLOCK/queue/scheduler >> $LOG_FILE
    sync && /sbin/hdparm -tT /dev/$BLOCK >> $LOG_FILE

    echo "Тест DD" >> $LOG_FILE
    for i in 1 2 3 4 5; do
        time dd if=$BASEDIR/path of=./benchfile bs=1M count=19900 conv=fdatasync,notrunc >> $LOG_FILE
    done

    echo "Тест TAR" >> $LOG_FILE
    for i in 1 2 3 4 5; do
        time tar xJf $BASEDIR/linux-3.13.7.tar.xz >> $LOG_FILE
    done
}

main() {
    clear
    echo "Выберите диск с планировщиком ввода-вывода"
    lsblk -l
    read -p "Введите имя диска (sda/sdb/..): " BLOCK
    clear

    while true; do
        echo "Меню планировщика ввода-вывода"
        echo "Выберите опцию:"
        echo "1. Просмотр системной информации"
        echo "2. Начать тесты планировщика ввода-вывода"
        echo "3. Выход"

        read -p "Введите 1-3: " choice

        case $choice in
            1) clear; I_B ;;
            2) clear;
               echo "Запуск тестов планировщика ввода-вывода..." >> $LOG_FILE
               > $LOG_FILE  # Очистить лог-файл
               for scheduler in none mq-deadline kyber bfq; do
                   run_io_tests $scheduler
               done
               echo "Тесты планировщика ввода-вывода завершены. Результаты можно найти в $LOG_FILE."
               ;;
            3) exit ;;
            *) echo "Неверная опция. Выберите корректную опцию." ;;
        esac
    done
}

main
