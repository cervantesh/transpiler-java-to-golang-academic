package main

import "fmt"

func main() {
	var ready bool = true
	var blocked bool = false
	if ready && blocked || ready {
		fmt.Println("go")
	} else {
		fmt.Println("stop")
	}
}
