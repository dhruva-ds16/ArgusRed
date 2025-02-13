
package main

import (
	"net/http"
	"log"
	"github.com/argusred/ArgusRed/loginController"
)

func main() {
	http.HandleFunc("/login", login)
	log.Println("Server is running on port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
