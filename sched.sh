#!/bin/bash

BLOCK=""
BASEDIR="/tmp"

I_B() {
    echo -e "${BPurple}I/O Scheduler Information${Color_Off}"
    iostat -p
    echo -e "${BYellow}Current I/O Scheduler:${Color_Off}"
    cat /sys/block/$BLOCK/queue/scheduler
    echo -e "${Green}Disk Information${Color_Off}"
    lsblk -l
}

T_S() {
    echo "I/O Scheduler Tests" | boxes -d tux -p a1
    wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.13.7.tar.xz -P $BASEDIR

    for T in none mq-deadline kyber bfq; do
        rm -rf $BASEDIR/linux-3.13.7
        rm $BASEDIR/benchfile

        echo 3 > /proc/sys/vm/drop_caches
        echo -e "${BYellow}SCHEDULER\t--->\t$T${Color_Off}"
        echo -e "${BPurple}IOSTAT_INFORMATION${Color_Off}"
        iostat -p

        echo -e "${BPurple}TEST_BONNIE${Color_Off}"
        mkdir $BASEDIR/boniee_test_dir
        bonnie++ -u root -d $BASEDIR/boniee_test_dir
        rm -rf $BASEDIR/boniee_test_dir
        echo 3 > /proc/sys/vm/drop_caches

        echo -e "${BPurple}TEST_FIO.Test random read/write${Color_Off}"
        sudo fio --filename=$BASEDIR/path --size=1GB --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=10 --numjobs=4 --time_based --group_reporting --name=job_name --eta-newline=1
        echo 3 > /proc/sys/vm/drop_caches

        echo -e "${BPurple}TEST_HDPARM${Color_Off}"
        echo $T > /sys/block/$BLOCK/queue/scheduler
        cat /sys/block/$BLOCK/queue/scheduler
        sync && /sbin/hdparm -tT /dev/$BLOCK
        echo "----"
        echo 3 > /proc/sys/vm/drop_caches

        echo -e "${BPurple}TEST_DD${Color_Off}"
        for i in 1 2 3 4 5; do
            time dd if=$BASEDIR/path of=./benchfile bs=1M count=19900 conv=fdatasync,notrunc
            echo 3 > /proc/sys/vm/drop_caches
        done
        echo 3 > /proc/sys/vm/drop_caches

        echo -e "${BPurple}TEST_TAR${Color_Off}"
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

main() {
    clear
    echo -e "${Green}Choose disk which has I/O Schedulers${Color_Off}"
    lsblk -l
    read -p "Enter disk name (sda/sdb/..): " BLOCK
    clear

    while true; do
        echo -e "${BPurple}\t\t\tI/O Schedulers Menu\nChoose option:${Color_Off}\n\t${Green}1. View system information\n\t2. Start I/O Scheduler tests\n\t3. Exit${Color_Off}"
        read -p "Enter 1-3: " choice

        case $choice in
            1) clear; I_B ;;
            2) clear; T_S ;;
            3) exit ;;
            *) echo "Invalid option, please select a valid option." ;;
        esac
    done
}

main
