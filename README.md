
# ChatFlow - Messaging Application

## Overview

ChatFlow is a Ruby on Rails 7 application that supports:

* **User Authentication** with [Devise](https://github.com/heartcombo/devise)
* **Private & Group Conversations** (with 2+ participants)
* **Messaging System** with timestamps and history
* **Real-time Message Delivery** via [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html)
* **RESTful API** designed for both UI and CLI usage


## Tech Stack

* **Backend:** Ruby on Rails 7, PostgreSQL
* **Auth:** Devise + Session-based cookies
* **Realtime:** ActionCable (WebSockets)
* **API Format:** JSON
* **Frontend:** Minimal Rails views (can be replaced with SPA/mobile)

---

## 1. Setup Instructions

### 1.1 Clone the repository

```bash
git clone <repo-url>
cd chatflow
```

### 1.2 Install dependencies

```bash
bundle install
yarn install --check-files
```

### 1.3 Setup the database

```bash
bin/rails db:create db:migrate
```

### 1.4 Seed sample data (users, conversation, messages)

```bash
bin/rails runner "
u1 = User.create!(email:'alice@example.com',username:'alice',password:'secret123')
u2 = User.create!(email:'bob@example.com',username:'bob',password:'secret123')
conv = Conversation.create!(title:'Seed Chat')
ConversationParticipant.create!(conversation: conv, user: u1)
ConversationParticipant.create!(conversation: conv, user: u2)
Message.create!(conversation: conv, user: u1, body: 'Hi Bob, this is Alice!')
Message.create!(conversation: conv, user: u2, body: 'Hey Alice! Good to hear from you.')
"
```

---

## 2. Running the Application

```bash
bin/rails s
```

The server will start at **[http://localhost:3000](http://localhost:3000)**

---

## 3. Testing via CLI

### 3.1 Log in as Alice

```bash
curl -i -c cookies_alice.txt -X POST http://localhost:3000/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"alice@example.com","password":"secret123"}}'
```

### 3.2 Log in as Bob

```bash
curl -i -c cookies_bob.txt -X POST http://localhost:3000/users/sign_in \
  -H "Content-Type: application/json" \
  -d '{"user":{"email":"bob@example.com","password":"secret123"}}'
```

### 3.3 View Alice's profile (verifies session works)

```bash
curl -i -b cookies_alice.txt -H "Accept: application/json" http://localhost:3000/users/me
```

### 3.4 List Alice's conversations

```bash
curl -i -b cookies_alice.txt -H "Accept: application/json" http://localhost:3000/conversations
```

### 3.5 Create a new conversation (Alice → Bob)

```bash
curl -i -b cookies_alice.txt -X POST http://localhost:3000/conversations \
  -H "Content-Type: application/json" \
  -d '{"participant_ids":[2],"title":"CLI Chat"}'
```

### 3.6 Send a message as Alice

```bash
curl -i -b cookies_alice.txt -X POST http://localhost:3000/conversations/1/messages \
  -H "Content-Type: application/json" \
  -d '{"body":"Hello from Alice via CLI"}'
```

### 3.7 View conversation messages as Bob

```bash
curl -i -b cookies_bob.txt -H "Accept: application/json" http://localhost:3000/conversations/1/messages
```

---

## 4. Real-time Messaging

* ActionCable is mounted at `/cable`
* A frontend or WebSocket client can connect and subscribe to `ConversationsChannel` to receive live message updates.

---

## 5. Notes

you may also run setup.sh that installs deps, prepares the DB, seeds two users + a conversation + messages (idempotently), and then prints copy-paste CLI commands to test the app.
