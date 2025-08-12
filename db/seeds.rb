puts "Clearing old data..."
Message.delete_all
ConversationParticipant.delete_all
Conversation.delete_all
User.delete_all

puts "Creating users..."
alice = User.create!(
  email: "a123@b.com",
  username: "alice123",
  password: "secret123"
)

test_user = User.create!(
  email: "test123c@d.com",
  username: "test123",
  password: "secret123"
)

puts "Creating conversation..."
conversation = Conversation.create!(
  title: "Seeded Chat"
)

puts "Adding participants..."
ConversationParticipant.create!(conversation: conversation, user: alice)
ConversationParticipant.create!(conversation: conversation, user: test_user)

puts "Creating messages..."
Message.create!(conversation: conversation, user: alice, body: "Hey Test! How’s it going?")
Message.create!(conversation: conversation, user: test_user, body: "Hi Alice! All good, working on the chat app.")
Message.create!(conversation: conversation, user: alice, body: "Nice! This is from seeds.rb")

puts "Seed data created!"
puts "Alice's login: email=a123@b.com password=secret123"
puts "Test's login: email=test123c@d.com password=secret123"
