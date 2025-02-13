
package main

var users = map[string]string{
	"user1": "password1",
	"user2": "password2",
}

func authenticate(username, password string) bool {
	pass, exists := users[username]
	return exists && pass == password
}
