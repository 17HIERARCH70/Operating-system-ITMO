#!/bin/bash

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
            gcc -o ~/ForkBomb/ForkBombLin ~/ForkBomb/ForkBombLin.c
            ~/ForkBomb/ForkBombLin &
            pid=$!
            sleep 10
            kill $pid 
            rm -f ~/ForkBomb/ForkBombLin 
        elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin" ]]; then
            # Компиляция и запуск ForkBomb для Windows
            gcc -o ~/ForkBomb/ForkBombWin ~/ForkBomb/ForkBombWin.c
            ~/ForkBomb/ForkBombWin.exe &
            pid=$! 
            sleep 10
            taskkill /F /PID $pid 
            rm -f ~/ForkBomb/ForkBombWin.exe 
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
            gcc -o ~/MemBomb/MemBombLin ~/MemBomb/MemBombLin.c
            ~/MemBomb/MemBombLin &
            pid=$! 
            sleep 10
            kill $pid 
            rm -f ~/MemBomb/MemBombLin 
        elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin" ]]; then
            # Компиляция и запуск MemBomb для Windows
            gcc -o ~/MemBomb/MemBombWin ~/MemBomb/MemBombWin.c
            ~/MemBomb/MemBombWin.exe &
            pid=$! 
            sleep 10
            taskkill /F /PID $pid 
            rm -f ~/MemBomb/MemBombWin.exe
        else
            echo "Не удалось определить ОС"
        fi
    else
        echo "Запуск MemBomb отменен"
    fi
else
    echo "Неверный выбор программы"
fi
