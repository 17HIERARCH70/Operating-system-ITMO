#!/bin/bash

ForkBombLin(){
     gcc -o ForkBomb ForkBombLin.c
            echo "Run..."
            sudo ./ForkBomb &
            pid=$!
            sleep 10
            kill $pid 
            rm -f ForkBombLin 
}

ForkBombWin{
    gcc -o /ForkBomb /ForkBombWin.c
            /ForkBomb.exe &
            pid=$! 
            sleep 10
            taskkill /F /PID $pid 
            rm -f ForkBomb.exe 
}

MembombLin() {
     gcc -o MemBomb MemBombLin.c
            echo "Run..."
			sudo touch /etc/systemd/system/KillLinux.service
			sudo chmod 644 /etc/systemd/system/KillLinux.service

			sudo tee /etc/systemd/system/KillLinux.service << EOF
[Unit]
Description=KillLinux
After=network.target

[Service]
ExecStart=$(find $work_dir/MemBomb/ -type f -name "Membomb" -executable -print -quit)

[Install]
WantedBy=default.target
EOF
			sudo systemctl unmask KillLinux.service
			sudo systemctl daemon-reload
			sudo systemctl enable KillLinux.service
			sudo systemctl start KillLinux.service
            sudo ./MemBomb &
            pid=$! 
            sleep 10
            kill $pid 
            rm -f MemBombLin 
}

MemBombWin(){
    gcc -o MemBombWin MemBombWin.c
            /MemBombWin.exe &
            pid=$! 
            sleep 10
            taskkill /F /PID $pid 
            rm -f MemBombWin.exe
}


echo "Добро пожаловать!"
echo "Список программ:"
echo "1) ForkBomb"
echo "2) MemBomb"

read -p "Выберите программу (1/2): " choice

if [ "$choice" == "1" ]; then
    read -p "Вы уверены, что хотите запустить ForkBomb? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Компиляция и запуск ForkBomb для Linux
            cd $work_dir/ForkBomb
            ForkBombLin
        elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin" ]]; then
            # Компиляция и запуск ForkBomb для Windows
            cd $work_dir/ForkBomb
            ForkBombWin
        else
            echo "Не удалось определить ОС"
        fi
    else
        echo "Запуск ForkBomb отменен"
    fi
elif [ "$choice" == "2" ]; then
    read -p "Вы уверены, что хотите запустить MemBomb? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Компиляция и запуск MemBomb для Linux
            cd $work_dir/MemBomb
            MembombLin
        elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin" ]]; then
            # Компиляция и запуск MemBomb для Windows
            cd $work_dir/MemBomb
            MemBombWin
        else
            echo "Не удалось определить ОС"
        fi
    else
        echo "Запуск MemBomb отменен"
    fi
else
    echo "Неверный выбор программы"
fi
