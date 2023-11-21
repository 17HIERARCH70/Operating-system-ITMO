// server.cpp
#include <iostream>
#include <fstream>
#include <cstring>
#include <unistd.h>
#include <arpa/inet.h>

void logMessage(const std::string& message) {
    std::ofstream logFile("server.log", std::ios::app);
    logFile << message << std::endl;
}

int main() {
    int serverSocket, clientSocket;
    struct sockaddr_in serverAddr, clientAddr;
    socklen_t addrLen = sizeof(clientAddr);
    char buffer[1024];

    // Создание сокета
    serverSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (serverSocket == -1) {
        perror("Error creating socket");
        return 1;
    }

    // Настройка структуры сервера
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = INADDR_ANY;
    serverAddr.sin_port = htons(8888);

    // Установка опции SO_REUSEADDR
    int reuse = 1;
    if (setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse)) < 0) {
        perror("Error setting SO_REUSEADDR option");
        return 1;
    }

    logMessage("Server started with SO_REUSEADDR option enabled.");

    // Привязка сокета
    if (bind(serverSocket, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) < 0) {
        perror("Error binding socket");
        return 1;
    }

    // Прослушивание порта
    if (listen(serverSocket, 5) < 0) {
        perror("Error listening on socket");
        return 1;
    }

    logMessage("Server listening on port 8888...");

    // Принимаем соединение
    clientSocket = accept(serverSocket, (struct sockaddr*)&clientAddr, &addrLen);
    if (clientSocket < 0) {
        perror("Error accepting connection");
        return 1;
    }

    // Чтение данных от клиента
    memset(buffer, 0, sizeof(buffer));
    if (read(clientSocket, buffer, sizeof(buffer)) < 0) {
        perror("Error reading from socket");
        return 1;
    }

    logMessage("Received message from client: " + std::string(buffer));

    // Закрываем сокеты
    close(clientSocket);
    close(serverSocket);

    return 0;
}
