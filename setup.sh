##!/usr/bin/env bash
#set -euo pipefail
#
#echo "=== ChatFlow setup ==="
#
## 1) Ruby/Bundler
#ruby -v
#if ! bundle -v >/dev/null 2>&1; then
#  echo "Bundler not found. Installing..."
#  gem install bundler
#fi
#
#echo "==> Installing gems"
#bundle install
#
## 2) (Optional) JS deps when using importmap (safe to keep)
#if command -v yarn >/dev/null 2>&1; then
#  echo "==> Installing JS dependencies (yarn)"
#  yarn install --check-files || true
#else
#  echo "(!) yarn not found; skipping JS deps (importmap works without it)"
#fi
#
## 3) Database
#echo "==> Preparing database (create + migrate)"
#bin/rails db:prepare
#
## 4) Seed data (idempotent)
#echo "==> Seeding users, conversation, messages (idempotent)"
#bin/rails - runner <<'RUBY'
#alice = User.find_or_create_by!(email: "alice@example.com") do |u|
#  u.username = "alice"
#  u.password = "secret123"
#end
#
#bob = User.find_or_create_by!(email: "bob@example.com") do |u|
#  u.username = "bob"
#  u.password  = "secret123"
#end
#
#conv = Conversation.find_or_create_by!(title: "Seed Chat") do |c|
#  # if your Conversation has a 'group' boolean, ensure a default:
#  c.group = false if c.respond_to?(:group) && c.group.nil?
#end
#
## Ensure participants exist
#[alice, bob].each do |u|
#  ConversationParticipant.find_or_create_by!(conversation: conv, user: u)
#end
#
## Ensure at least a couple of messages exist
#if conv.messages.count == 0
#  Message.create!(conversation: conv, user: alice, body: "Hi Bob, this is Alice (seed)!")
#  Message.create!(conversation: conv, user: bob,   body: "Hey Alice! Good to hear from you (seed).")
#end
#
#puts "Seed complete."
#puts "Alice: #{alice.id} (alice@example.com / secret123)"
#puts "Bob:   #{bob.id} (bob@example.com / secret123)"
#puts "Conversation: #{conv.id} (\"#{conv.title}\")"
#RUBY
#
## 5) ActionCable note
#if [ -f config/cable.yml ]; then
#  echo "==> ActionCable configured (see config/cable.yml)."
#  echo "    Dev uses async by default; Redis recommended for parity."
#fi
#
#echo
#echo "=== Setup finished ==="
#echo "Start the server:"
#echo "  bin/rails s"
#echo
#echo "=== CLI test (copy/paste) ==="
#cat <<'CLI'
#
## 1) Log in as Alice (stores cookies in cookies_alice.txt)
#curl -i -c cookies_alice.txt -X POST http://localhost:3000/users/sign_in \
#  -H "Content-Type: application/json" \
#  -d '{"user":{"email":"alice@example.com","password":"secret123"}}'
#
## 2) Log in as Bob (stores cookies in cookies_bob.txt)
#curl -i -c cookies_bob.txt -X POST http://localhost:3000/users/sign_in \
#  -H "Content-Type: application/json" \
#  -d '{"user":{"email":"bob@example.com","password":"secret123"}}'
#
## 3) Verify auth
#curl -s -b cookies_alice.txt -H "Accept: application/json" http://localhost:3000/users/me
#curl -s -b cookies_bob.txt   -H "Accept: application/json" http://localhost:3000/users/me
#
## 4) Create a new conversation (Alice -> Bob)
##    Replace BOB_ID with the number printed in the seed output (e.g., 2).
#curl -i -b cookies_alice.txt -X POST http://localhost:3000/conversations \
#  -H "Content-Type: application/json" -H "Accept: application/json" \
#  -d '{"participant_ids":[BOB_ID],"title":"CLI Chat"}'
## → Response includes: {"id": <CONV_ID>}
#
## 5) Send messages
#curl -i -b cookies_alice.txt -X POST http://localhost:3000/conversations/CONV_ID/messages \
#  -H "Content-Type: application/json" -H "Accept: application/json" \
#  -d '{"body":"Hello from Alice via CLI"}'
#
#curl -i -b cookies_bob.txt -X POST http://localhost:3000/conversations/CONV_ID/messages \
#  -H "Content-Type: application/json" -H "Accept: application/json" \
#  -d '{"body":"Hi Alice, Bob here via CLI"}'
#
## 6) Read history
#curl -s -b cookies_alice.txt -H "Accept: application/json" \
#  "http://localhost:3000/conversations/CONV_ID/messages?limit=20" | jq .
#
#CLI
#
#echo
#echo "Tip: if a POST 302-redirects to /users/sign_in, add:"
#echo '  -H "Accept: application/json"'
#echo "and ensure you're using the same host (localhost) as when you logged in."
