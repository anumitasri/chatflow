
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
git clone https://github.com/anumitasri/chatflow.git
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

You can also seed data manually:

bin/rails db:seed
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

## Part 2

# Technical Documentation

## Architecture Overview

### High-level System Design

```
+--------------------+        Web (HTTP) / WS (ActionCable)        +--------------------+
|   Browser / CLI    |  <----------------------------------------> |   Rails 7 App      |
|  (Stimulus / curl) |                                            |  (Puma workers)    |
+--------------------+                                            +----------+---------+
                                                                           |
                                                                           | ActiveRecord
                                                                           v
                                                                  +--------------------+
                                                                  |   PostgreSQL       |
                                                                  | (Users/Convos/Msg) |
                                                                  +--------------------+

[Realtime option for scale]
+--------------------+   Pub/Sub   +--------------------+   Fanout to cable workers
| Rails Cable Pub    | <---------> |     Redis          | <------------------------+
| (ActionCable)      |             +--------------------+                          |
+--------------------+                                                             
```

**Flow**

* Users authenticate with Devise (session cookies).
* REST JSON endpoints handle conversations/messages.
* Real-time message delivery uses ActionCable; clients subscribe per conversation.
* PostgreSQL stores users, conversations, membership (join table), and messages.

### Technology Choices & Rationale

* **Rails 7 + Devise**: fastest path to reliable auth and CRUD, strong security defaults.
* **ActionCable**: built-in WebSockets tightly integrated with Rails; `stream_for` maps cleanly to conversation streams.
* **PostgreSQL**: relational consistency, indexing, simple time-based pagination.
* **Importmap + Stimulus** (tiny UI): zero-build JS; small footprint. CLI-first API also supported.
* **Session auth** over JWT for MVP: simpler dev/testing; can add JWT later for mobile/API clients.

### Database Schema Design

* **User**: `email` (unique), `encrypted_password`, `username`, `name`, `avatar_url`, timestamps.
* **Conversation**: `title`, `group:boolean`, timestamps.
* **ConversationParticipant** *(join)*: `conversation_id`, `user_id` (unique composite index), timestamps.
* **Message**: `conversation_id`, `user_id`, `body:text`, timestamps.

**Indexes**

* `conversation_participants (conversation_id, user_id) UNIQUE`
* `messages (conversation_id, created_at)` (supports history pagination)
* `users (email) UNIQUE`

**Access Control**

* All conversation and message queries are scoped through `conversation_participants` so only members can read/write.

### API Design Decisions

* **Resource modeling**: `/conversations` as parent, `/conversations/:id/messages` nested.
* **Pagination**: cursor-like via `before`/`after` (ISO8601) + `limit` for messages; uses `created_at`.
* **Error shapes**:

  * `401` when unauthenticated
  * `404/403` when not a participant (implemented as a scoped `find_by!`)
  * `422` with `errors: [...]` for validation failures
* **CSRF**:

  * For JSON API endpoints (Devise create/destroy, conversations/messages create), CSRF is skipped to enable CLI testing.
  * Web UI retains CSRF protections.
* **Realtime**:

  * `ConversationsChannel` authorizes by checking membership; uses `stream_for(conversation)`; broadcasts on `MessagesController#create`.

---

## Scaling Considerations

### Goal: \~10K concurrent users

**Web tier**

* **Puma**: multiple workers + threads; horizontal autoscale behind a load balancer.
* Separate **web** (HTTP) and **cable** (WebSocket) processes/pods for better headroom/GC behavior.

**ActionCable**

* Use **Redis** adapter in all non-dev environments for pub/sub fanout.
* Sticky sessions (LB) for WS or use `AnyCable` if pushing beyond standard ActionCable throughput.

**Database**

* Add/verify indexes (`messages(conversation_id, created_at)` and join table unique index).
* Use **read replicas** for heavy fetches if needed (message history); writes go to primary.
* Batch writes if adding delivery receipts/typing indicators at scale.

**Caching**

* Cache conversation membership (`user_id` → `conversation_ids`) in Redis for auth checks.
* HTTP caching for conversation lists with short TTL; ETag on message lists when applicable.

**Bottlenecks Anticipated**

* **Hot conversations** (many subscribers): broadcast fanout pressure on Cable/Redis.

  * Mitigate with Redis, partitioned cable workers, and optional **broadcast coalescing** (e.g., compact multiple events).
* **DB write hotspots** on `messages` for viral rooms:

  * Consider **append-only** partitioning by `conversation_id` or by time; maintain composite indexes per partition.
* **N+1 queries** on lists:

  * Use `includes(:users)` where rendering participant info; keep message payloads lean (no heavy joins).

**What we’d change for higher scale**

* **Background jobs** for side effects (analytics, read receipts) via Sidekiq/Redis.
* **Event-driven** ingestion (Kafka) for extremely high write rates; materialized views/read models for fast timelines/search.
* **AnyCable** or Phoenix (Elixir) for WebSocket heavy duty if requirements exceed Rails Cable design envelope.
* **Object storage** + CDN for avatars/media if/when attachments are added.

---

## Trade-offs and Decisions

### Key Technical Decisions

* **Devise sessions vs JWT**: chose sessions for simplicity and quick local/CLI testing. JWT can be added for mobile clients.
* **ActionCable vs polling/SSE**: chose ActionCable for true bidirectional real-time and clean server broadcast semantics.
* **Importmap/Stimulus vs SPA**: minimal UI to focus on backend quality and real-time; CLI remains first-class.
* **Cursor by timestamp**: simple, index-friendly pagination that is “good enough” for chat history.

### Alternatives Considered

* **devise\_token\_auth/JWT** from day one: better for stateless APIs; deferred to keep MVP small and reduce auth surface.
* **SSE/polling**: simpler infra; rejected for message latency and extra server load vs WebSockets.
* **No join table** (store participant IDs as array in `conversations`): faster to prototype but harms relational integrity, queries, and indexing.
* **MongoDB** for message storage: flexible schema and append performance; Postgres chosen for transactional integrity and familiarity.


## Appendix: Current Endpoints

* **Auth (Devise)**

  * `POST /users/sign_in` – session login (JSON supported for CLI)
  * `DELETE /users/sign_out` – logout
  * `POST /users` – registration (web form)

* **Users**

  * `GET  /users/me` – current user
  * `PUT  /users/me` – update profile (`name`, `avatar_url`, `username`)

* **Conversations**

  * `GET  /conversations` – list my conversations
  * `GET  /conversations/:id` – show (guarded by membership)
  * `POST /conversations` – `{ participant_ids: [..], title?: string }` (group if participants ≥ 3)

* **Messages**

  * `GET  /conversations/:conversation_id/messages?before&after&limit`
  * `POST /conversations/:conversation_id/messages` – `{ body: "..." }`






