// server
package main

import (
	"fmt"
	"net"
	"syscall"
)

const (
	PORT = 2556
)

func main() {
	listener, err := net.Listen("tcp", fmt.Sprintf(":%d", PORT))
	if err != nil {
		fmt.Println("Error creating listener:", err)
		return
	}
	defer listener.Close()

	fmt.Println("Server listening on port", PORT)

	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Println("Error accepting connection:", err)
			continue
		}

		// Set socket options
		err = setSocketOptions(conn)
		if err != nil {
			fmt.Println("Error setting socket options:", err)
			return
		}

		go handleConnection(conn)
	}
}

func setSocketOptions(conn net.Conn) error {
	rawConn, err := conn.(syscall.Conn).SyscallConn()
	if err != nil {
		return err
	}

	err = rawConn.Control(func(fd uintptr) {
		// Set socket options here
		err := syscall.SetsockoptInt(int(fd), syscall.SOL_SOCKET, syscall.SO_KEEPALIVE, 0)
		if err != nil {
			fmt.Println("Error setting SO_KEEPALIVE option:", err)
		}

		err = syscall.SetsockoptInt(int(fd), syscall.SOL_SOCKET, syscall.SO_DONTROUTE, 0)
		if err != nil {
			fmt.Println("Error setting SO_DONTROUTE option:", err)
		}

		err = syscall.SetsockoptInt(int(fd), syscall.IPPROTO_TCP, syscall.TCP_NODELAY, 0)
		if err != nil {
			fmt.Println("Error setting TCP_NODELAY option:", err)
		}
		// Add more options as needed
	})
	return err
}

func handleConnection(conn net.Conn) {
	defer conn.Close()

	fmt.Println("Client connected:", conn.RemoteAddr())

	// Receive and print incoming messages 100 times
	for i := 0; i < 10000; i++ {
		message := make([]byte, 5000)
		n, err := conn.Read(message)
		if err != nil {
			if err.Error() == "EOF" {
				fmt.Println("Client disconnected:", conn.RemoteAddr())
			} else {
				fmt.Println("Error reading message from client:", err)
			}
			break // Break the loop on read error
		}

		// Trim null bytes and print the received message
		receivedMessage := message[:n]
		fmt.Printf("Received message from client %s: %s\n", conn.RemoteAddr(), receivedMessage)

		// Respond to the client
		_, err = conn.Write([]byte("Hello"))
		if err != nil {
			fmt.Println("Error sending response to client:", err)
			break // Break the loop on write error
		}
	}

	fmt.Println("Server finished handling client:", conn.RemoteAddr())
}
