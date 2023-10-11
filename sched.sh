#!/bin/bash

BLOCK()
{
  echo "Выберите диск с доступными планировщиками ввода-вывода"
  lsblk -l;
  read -p "Введите имя диска (sda/sdb/..): " BLOCK_
  schedulers="/sys/block/$BLOCK_/queue/scheduler"
  clear
}

A_S()
{
  echo "Доступные планировщики ввода-вывода"
  echo "[имя] - планировщик по умолчанию"
  awk -v OFS="" -v FPAT='\\[[^]]*\\]|"[^"]*"|[^[:space:]]+' '{
    for (i=1; i<=NF; i++) 
    {
      gsub(/^[]|[]$/, $i)
      $i =  i ".\""$i"\"\n"
    }
  }' "$schedulers"
}

T_S()
{
  echo "Тесты планировщика ввода-вывода"
  wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.13.7.tar.xz
  for T in none mq-deadline kyber bfq;
  do
    sudo rm -rf "$BASEDIR/linux-3.13.7"
    sudo rm "$BASEDIR/benchfile"
    echo 3 > /proc/sys/vm/drop_caches
    echo "Планировщик ---> $T"
    echo "Информация по IOSTAT"
    iostat -p
    echo "Тестирование BONNIE"
    mkdir boniee_test_dir
    bonnie++ -u root -d "$BASEDIR/boniee_test_dir"
    rm -rf boniee_test_dir
    echo 3 > /proc/sys/vm/drop_caches
    echo "Тест FIO. Случайное чтение/запись"
    sudo fio --filename="$BASEDIR/path" --size=1GB --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=10 --numjobs=4 --time_based --group_reporting --name=job_name --eta-newline=1
    echo 3 > /proc/sys/vm/drop_caches
    echo "Тест HDPARM"
    echo $T > /sys/block/$BLOCK_/queue/scheduler; 
    cat /sys/block/$BLOCK_/queue/scheduler; 
    sync && /sbin/hdparm -tT /dev/$BLOCK_ && echo "----"; 
    echo 3 > /proc/sys/vm/drop_caches
    echo "Тест DD"
    for i in 1 2 3 4 5; 
    do
      time dd if="$BASEDIR/path" of="./benchfile" bs=1M count=19900 conv=fdatasync,notrunc
      echo 3 > /proc/sys/vm/drop_caches
    done
    echo 3 > /proc/sys/vm/drop_caches
    echo "Тест TAR"
    for i in 1 2 3 4 5; 
    do
      time tar xJf linux-3.13.7.tar.xz
      echo 3 > /proc/sys/vm/drop_caches
    done
  done
  rm "$BASEDIR/path"
  rm -rf "$BASEDIR/linux-3.13.7"
  rm "$BASEDIR/benchfile"
  rm "$BASEDIR/linux-3.13.7.tar.xz"
}

Schedulers()
{
  echo "Меню планировщиков ввода-вывода"
  echo "Выберите опцию:"
  echo "1. Просмотр информации о системе"
  echo "2. Доступные планировщики ввода-вывода"
  echo "3. Запустить тесты планировщика ввода-вывода"
  echo "4. Вернуться в главное меню"
  echo "5. Выход"
  read -p "Введите 1-5: " Switch_Option
  case $Switch_Option in
    1) clear & I_B;;
    2) clear & A_S;;
    3) clear & T_S;;
    4) clear & main;;
    5) clear; exit;;
  esac
  Schedulers
}

main()
{
  BASEDIR=$(dirname "$0")
  clear
  echo "Главное меню"
  echo "1. Информация о диске"
  echo "2. Планировщики ввода-вывода"
  echo "3. Выход"
  read -p "Введите 1-3: " choice
  case $choice in
    1) clear & I_B;;
    2) clear & Schedulers;;
    3) clear; exit;;
  esac
}

main
