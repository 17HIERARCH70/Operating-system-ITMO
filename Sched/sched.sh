#!/bin/bash

os=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
work_dir=$PWD

I_B()
{
	echo "____Информация о системе____"
	hostnamectl
}

A_S()
{
	echo "____Доступные планировщики ввода-вывода____"
	echo "[имя] - планировщик по умолчанию"
	awk -v OFS="" -v FPAT='\\[[^]]*\\]|"[^"]*"|[^[:space:]]+' '{
		for (i=1; i<=NF; i++) 
		{
			gsub(/^[]|[]$/,$i)
			$i =  i ".\""$i"\"\n"
		}
	} 1' $schedulers
}
A_S_After_Change()
{
	echo "Планировщик ввода-вывода был изменен!"
}

T_S()
{
	echo "Тесты планировщика ввода-вывода" | boxes -d tux -p a1 
	wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.13.7.tar.xz

	
	for T in none mq-deadline kyber bfq;
	do

		sudo rm -rf $BASEDIR/linux-3.13.7
		sudo rm $BASEDIR/benchfile
	
		echo 3 > /proc/sys/vm/drop_caches
		
		echo "ПЛАНИРОВЩИК -> "$T""
		echo "Информация о диске"
		
		iostat -p
		
		echo "Тестирование Bonnie++"
		mkdir boniee_test_dir
		bonnie++ -u root -d $BASEDIR/boniee_test_dir
		rm -rf boniee_test_dir
		echo 3 > /proc/sys/vm/drop_caches
		
		echo "Тестирование FIO. Случайное чтение/запись"
		sudo fio --filename=$BASEDIR/path --size=1GB --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=10 --numjobs=4 --time_based --group_reporting --name=job_name --eta-newline=1
		echo 3 > /proc/sys/vm/drop_caches
		
		echo "Тестирование hdparm"
		echo $T > /sys/block/$BLOCK_/queue/scheduler; 
		cat /sys/block/$BLOCK_/queue/scheduler; 
		sync && /sbin/hdparm -tT /dev/$BLOCK_ && echo "----"; 
		echo 3 > /proc/sys/vm/drop_caches
		
		echo "Тестирование dd"
		for i in 1 2 3 4 5; 
		do
			time dd if=$BASEDIR/path of=./benchfile bs=1M count=19900 conv=fdatasync,notrunc
			echo 3 > /proc/sys/vm/drop_caches
		done
		echo 3 > /proc/sys/vm/drop_caches
		
		echo "Тестирование tar"
		for i in 1 2 3 4 5; 
		do
			time tar xJf linux-3.13.7.tar.xz
			echo 3 > /proc/sys/vm/drop_caches
		done
		
	done
	rm $BASEDIR/path
	rm -rf $BASEDIR/linux-3.13.7
	rm $BASEDIR/benchfile
	rm $BASEDIR/linux-3.13.7.tar.xz
}

C_P_Of_mq_deadline()
{
	echo "Вы можете изменить следующие параметры планировщика mq-deadline"
	echo "1. async_depth"
	echo "2. front_merges"
	echo "3. read_expire"
	echo "4. writes_starved"
	echo "5. fifo_batch"
	echo "6. prio_aging_expire"
	echo "7. write_expire"
	echo "8. Вернуться в главное меню"
	echo "9. Сбросить значения по умолчанию"
	read -p "Введите 1-9: " S_To_Change
	case $S_To_Change in
		1) echo "async_depth" && cat /sys/block/sda/queue/iosched/async_depth && read -p "Введите новое значение: " async_depth && echo $async_depth > /sys/block/sda/queue/iosched/async_depth && C_P_Of_mq_deadline ;;
		2) echo "front_merges" && cat /sys/block/sda/queue/iosched/front_merges && read -p "Введите новое значение: " front_merges && echo $front_merges > /sys/block/sda/queue/iosched/front_merges && C_P_Of_mq_deadline;;
		3) echo "read_expire" && cat /sys/block/sda/queue/iosched/read_expire && read -p "Введите новое значение: " read_expire && echo $read_expire > /sys/block/sda/queue/iosched/read_expire && C_P_Of_mq_deadline;;
		4) echo "writes_starved" && cat /sys/block/sda/queue/iosched/writes_starved && read -p "Введите новое значение: " writes_starved && echo $writes_starved > /sys/block/sda/queue/iosched/writes_starved && C_P_Of_mq_deadline;;
		5) echo "fifo_batch" && cat /sys/block/sda/queue/iosched/fifo_batch && read -p "Введите новое значение: " fifo_batch && echo $fifo_batch > /sys/block/sda/queue/iosched/fifo_batch && C_P_Of_mq_deadline;;
		6) echo "prio_aging_expire" && cat /sys/block/sda/queue/iosched/prio_aging_expire && read -p "Введите новое значение: " prio_aging_expire && echo $prio_aging_expire > /sys/block/sda/queue/iosched/prio_aging_expire && C_P_Of_mq_deadline;;
		7) echo "write_expire" && cat /sys/block/sda/queue/iosched/write_expire && read -p "Введите новое значение: " write_expire && echo $write_expire > /sys/block/sda/queue/iosched/write_expire && C_P_Of_mq_deadline;;
		8) echo 48 > /sys/block/sda/queue/iosched/async_depth && echo 1 > /sys/block/sda/queue/iosched/front_merges && echo 500 > /sys/block/sda/queue/iosched/read_expire && echo 2 > /sys/block/sda/queue/iosched/writes_starved && echo 16 > /sys/block/sda/queue/iosched/fifo_batch && echo 10000 > /sys/block/sda/queue/iosched/prio_aging_expire && echo 5000 > /sys/block/sda/queue/iosched/write_expire;;
		9) main;;
	esac
}

C_P_Of_kyber()
{
	echo "Вы можете изменить следующие параметры планировщика kyber"
	echo "1. read_lat_nsec"
	echo "2. write_lat_nsec"
	echo "3. Вернуться в главное меню"
	echo "4. Сбросить значения по умолчанию"
	read -p "Введите 1-2: " S_To_Change
	case $S_To_Change in
		1) echo "read_lat_nsec" && cat /sys/block/$BLOCK_/queue/iosched/read_lat_nsec && read -p "Введите новое значение: " read_lat_nsec && echo $read_lat_nsec > /sys/block/$BLOCK_/queue/iosched/read_lat_nsec && C_P_Of_kyber ;;
		2) echo "write_lat_nsec" && cat /sys/block/$BLOCK_/queue/iosched/write_lat_nsec && read -p "Введите новое значение: " write_lat_nsec && echo $write_lat_nsec > /sys/block/$BLOCK_/queue/iosched/write_lat_nsec && C_P_Of_kyber;;
		3) echo 2000000 > /sys/block/$BLOCK_/queue/iosched/read_lat_nsec && echo 10000000 > /sys/block/$BLOCK_/queue/iosched/write_lat_nsec;;
		4) main;;
	esac
	
}

C_P_Of_bfq()
{
	echo "Вы можете изменить следующие параметры планировщика BFQ"
	echo "1. back_seek_max"
	echo "2. fifo_expire_sync"
	echo "3. slice_idle"
	echo "4. timeout_sync"
	echo "5. back_seek_penalty"
	echo "6. low_latency"
	echo "7. slice_idle_us"
	echo "8. fifo_expire_async"
	echo "9. max_budget"
	echo "10. strict_guarantees"
	echo "11. Вернуться в главное меню"
	echo "12. Сбросить значения по умолчанию"
	read -p "Введите 1-12: " S_To_Change
	case $S_To_Change in
		1) echo "back_seek_max" && cat /sys/block/$BLOCK_/queue/iosched/back_seek_max && read -p "Введите новое значение: " back_seek_max && echo $back_seek_max > /sys/block/$BLOCK_/queue/iosched/back_seek_max && C_P_Of_bfq;;
		2) echo "fifo_expire_sync" && cat /sys/block/$BLOCK_/queue/iosched/fifo_expire_sync && read -p "Введите новое значение: " fifo_expire_sync && echo $fifo_expire_sync > /sys/block/$BLOCK_/queue/iosched/fifo_expire_sync && C_P_Of_bfq;;
		3) echo "slice_idle" && cat /sys/block/$BLOCK_/queue/iosched/slice_idle && read -p "Введите новое значение: " slice_idle && echo $slice_idle > /sys/block/$BLOCK_/queue/iosched/slice_idle && C_P_Of_bfq;;
		4) echo "timeout_sync" && cat /sys/block/$BLOCK_/queue/iosched/timeout_sync && read -p "Введите новое значение: " timeout_sync && echo $timeout_sync > /sys/block/$BLOCK_/queue/iosched/timeout_sync && C_P_Of_bfq;;
		5) echo "back_seek_penalty" && cat /sys/block/$BLOCK_/queue/iosched/back_seek_penalty && read -p "Введите новое значение: " back_seek_penalty && echo $back_seek_penalty > /sys/block/$BLOCK_/queue/iosched/back_seek_penalty && C_P_Of_bfq;;
		6) echo "low_latency" && cat /sys/block/$BLOCK_/queue/iosched/low_latency && read -p "Введите новое значение: " low_latency && echo $low_latency > /sys/block/$BLOCK_/queue/iosched/low_latency && C_P_Of_bfq;;
		7) echo "slice_idle_us" && cat /sys/block/$BLOCK_/queue/iosched/slice_idle_us && read -p "Введите новое значение: " slice_idle_us && echo $slice_idle_us > /sys/block/$BLOCK_/queue/iosched/slice_idle_us && C_P_Of_bfq;;
		8) echo "fifo_expire_async" && cat /sys/block/$BLOCK_/queue/iosched/fifo_expire_async && read -p "Введите новое значение: " fifo_expire_async && echo $fifo_expire_async > /sys/block/$BLOCK_/queue/iosched/fifo_expire_async && C_P_Of_bfq;;
		9) echo "max_budget" && cat /sys/block/$BLOCK_/queue/iosched/max_budget && read -p "Введите новое значение: " max_budget && echo $max_budget > /sys/block/$BLOCK_/queue/iosched/max_budget && C_P_Of_bfq;;
		10) echo "strict_guarantees" && cat /sys/block/$BLOCK_/queue/iosched/strict_guarantees && read -p "Введите новое значение: " strict_guarantees && echo $strict_guarantees > /sys/block/$BLOCK_/queue/iosched/strict_guarantees && C_P_Of_bfq;;
		11) echo 16384 > /sys/block/$BLOCK_/queue/iosched/back_seek_max && echo 8 > /sys/block/$BLOCK_/queue/iosched/slice_idle && echo 124 > /sys/block/$BLOCK_/queue/iosched/timeout_sync && echo 2 > /sys/block/$BLOCK_/queue/iosched/back_seek_penalty && echo 1 > /sys/block/$BLOCK_/queue/iosched/low_latency && echo 8000 >/sys/block/$BLOCK_/queue/iosched/slice_idle_us && echo 250 > /sys/block/$BLOCK_/queue/iosched/fifo_expire_async && echo 0 > /sys/block/$BLOCK_/queue/iosched/max_budget  && echo 0 > /sys/block/$BLOCK_/queue/iosched/strict_guarantees && echo 125 > /sys/block/$BLOCK_/queue/iosched/fifo_expire_sync ;;
		12) main;;
	esac
	
}

C_P_Of_Schedulers()
{
	read -p "Введите полное имя планировщика: " S_To_Change
	case $S_To_Change in
		"mq-deadline") C_P_Of_mq_deadline;;
		"kyber") C_P_Of_kyber;;
		"bfq") C_P_Of_bfq;;
	esac
	
}

C_D_Scheduler()
{
    cat /sys/block/$BLOCK_/queue/scheduler
	read -p "Введите полное имя планировщика: " S_To_Change
	echo $S_To_Change > /sys/block/$BLOCK_/queue/scheduler
	A_S_After_Change
}

BLOCK()
{
	echo "Выберите диск, для которого нужно настроить планировщик ввода-вывода"
	lsblk -l
	read -p "Введите имя диска (sda/sdb/..): " BLOCK_
	schedulers=/sys/block/$BLOCK_/queue/scheduler
	clear
}

Schedulers()
{
    
	echo "Меню планировщиков ввода-вывода"
	echo "Выберите опцию:"
	echo "1. Просмотр информации о системе"
	echo "2. Доступные планировщики ввода-вывода"
	echo "3. Изменить планировщик по умолчанию"
	echo "4. Изменить параметры планировщика (перед этим установите планировщик по умолчанию)"
	echo "5. Запустить тесты планировщика ввода-вывода"
	echo "6. Вернуться в главное меню"
	echo "7. Выход"

	read -p "Введите 1-7: " Switch_Option
	case $Switch_Option in
		1) clear & I_B;;
		2) clear & A_S;;
		3) clear; C_D_Scheduler ;;
		4) clear ; C_P_Of_Schedulers;;
		5) clear & T_S;;
		6) clear & main;;
		7) clear ; exit;;
	esac
	Schedulers
}

BLOCK ; clear ; Schedulers
