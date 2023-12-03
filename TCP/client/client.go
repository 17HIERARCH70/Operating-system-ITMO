// client
package main

import (
	"fmt"
	"net"
	"syscall"
	"time"
)

const (
	PORT = 2556
	IP   = "127.0.0.1"
)

func main() {
	conn, err := net.Dial("tcp", fmt.Sprintf("%s:%d", IP, PORT))
	if err != nil {
		fmt.Println("Error connecting to server:", err)
		return
	}
	defer conn.Close()

	// Set socket options
	err = setSocketOptions(conn)
	if err != nil {
		fmt.Println("Error setting socket options:", err)
		return
	}

	fmt.Println("Connected to server")
	startTime := time.Now()
	// Send "Hello" message 100 times
	for i := 0; i < 10000; i++ {
		msg := []byte("Hello")
		_, err := conn.Write(msg)
		if err != nil {
			fmt.Println("Error sending message:", err)
			break // Break the loop on write error
		}

		// Wait for the server's response
		buff := make([]byte, 5000)
		_, err = conn.Read(buff)
		if err != nil {
			fmt.Println("Error reading from server:", err)
			break // Break the loop on read error
		}
	}

	fmt.Println("Finished sending 'Hello' messages")
	elapsedTime := time.Since(startTime)
	fmt.Printf("Time: %.2f ms\n", elapsedTime.Seconds()*1000)
}

func setSocketOptions(conn net.Conn) error {
	file, err := conn.(*net.TCPConn).File()
	if err != nil {
		return err
	}
	defer file.Close()

	fd := file.Fd()

	// Disable TCP_QUICKACK
	err = syscall.SetsockoptInt(int(fd), syscall.IPPROTO_TCP, syscall.TCP_NODELAY, 1)
	if err != nil {
		return fmt.Errorf("error setting TCP_NODELAY option: %v", err)
	}

	// Add more options as needed

	return nil
}
