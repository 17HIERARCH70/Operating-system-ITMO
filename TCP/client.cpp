// client.cpp
#include <iostream>
#include <cstring>
#include <unistd.h>
#include <arpa/inet.h>

void logMessage(const std::string& message) {
    std::cout << message << std::endl;
}

int main() {
    int clientSocket;
    struct sockaddr_in serverAddr;
    char message[] = "Hello, server!";

    // Создание сокета
    clientSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (clientSocket == -1) {
        perror("Error creating socket");
        return 1;
    }

    // Настройка структуры сервера
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = inet_addr("127.0.0.1");
    serverAddr.sin_port = htons(8888);

    // Установка соединения
    if (connect(clientSocket, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) < 0) {
        perror("Error connecting to server");
        return 1;
    }

    // Отправка сообщения серверу
    if (write(clientSocket, message, strlen(message)) < 0) {
        perror("Error writing to socket");
        return 1;
    }

    logMessage("Message sent to server: " + std::string(message));

    // Закрытие сокета
    close(clientSocket);

    return 0;
}
