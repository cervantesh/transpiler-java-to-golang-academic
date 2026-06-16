package main

import "fmt"

func main() {
	if 3 <= 3 && 7 >= 6 && 2 < 4 && 9 > 1 {
		fmt.Println("inside")
	} else {
		fmt.Println("outside")
	}
}
