package main

import "fmt"

func combine(a int, b int, c int) int {
	return a + b*c
}

func main() {
	fmt.Println(combine(2, 3, 4))
}
