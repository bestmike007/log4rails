# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
user = User.create(email: 'i@bestmike007.com', password: '3a83f7f1290c2e8a8ef5f28007e76a68a7734f7785a0f8a0e88426cee164c37767784c42e717f5950001fe3ea4510c5ccdb797300a53d4f4abff6147c6002f9f')
Note.create(user_id: user.id, title: "Test", content: "Hello World!")
Note.create(user_id: user.id, title: "Test2", content: "Hello World!")