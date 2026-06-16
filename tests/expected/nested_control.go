package main

import "fmt"

func main() {
	var i int = 0
	var hits int = 0
	for i < 5 {
		if i > 2 {
			hits = hits + 1
		} else {
			hits = hits
		}
		i = i + 1
	}
	fmt.Println(hits)
}
