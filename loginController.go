package main

import (
	"encoding/json"
	"fyne.io/fyne/v2/app"
	"fyne.io/fyne/v2/container"
	"fyne.io/fyne/v2/widget"
	"net/http"
)

type Credentials struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func login(w http.ResponseWriter, r *http.Request) {
	var creds Credentials
	err := json.NewDecoder(r.Body).Decode(&creds)
	if err != nil {
		http.Error(w, "Invalid request payload", http.StatusBadRequest)
		return
	}

	if authenticate(creds.Username, creds.Password) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("Login successful"))
	} else {
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
	}
}

func main() {
	a := app.New()
	w := a.NewWindow("Login")

	usernameEntry := widget.NewEntry()
	usernameEntry.SetPlaceHolder("Username")

	passwordEntry := widget.NewPasswordEntry()
	passwordEntry.SetPlaceHolder("Password")

	loginButton := widget.NewButton("Login", func() {
		creds := Credentials{
			Username: usernameEntry.Text,
			Password: passwordEntry.Text,
		}

		if authenticate(creds.Username, creds.Password) {
			w.SetContent(widget.NewLabel("Login successful"))
		} else {
			w.SetContent(widget.NewLabel("Invalid credentials"))
		}
	})

	w.SetContent(container.NewVBox(
		usernameEntry,
		passwordEntry,
		loginButton,
	))

	w.ShowAndRun()
}
