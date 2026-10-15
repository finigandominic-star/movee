# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


puts "Cleaning database..."
User.destroy_all
Chain.destroy_all
InvolvedParty.destroy_all
Transaction.destroy_all
Property.destroy_all

puts "Creating users..."
# Admin Users
dom = User.create!(user_name: "Dom Finigan", email: "dom@moveee.me", password: "MoveeeAdmin123", company: "Moveee", admin: true)
joao = User.create!(user_name: "Joao", email: "joao@moveee.me", password: "app/views/chains/new.html.erb", company: "Moveee", admin: true)
sophia = User.create!(user_name: "Sophia", email: "sophia@moveee.me", password: "MoveeeAdmin123", company: "Moveee", admin: true)

# 1
sarah = User.create!(user_name: "Sarah Rizzoli", email: "sarah.rizzoli@harbourandheath.co.uk", password: "SaRi1234", company: "Harbour & Heath Properties")
#2
toni = User.create!(user_name: "Toni Martine", email: "t.martine@crownstoneestates.co.uk", password: "Ton1Crown", company: "Crownstone Estates")
# 3
mark = User.create!(user_name: "Mark McBride", email: "mcbride.mark@thistleandthatch.co.uk", password: "123Bride", company: "Thistle & Thatch Residential")
# 4
emily = User.create!(user_name: "Emily Song", email: "e.song@crownstoneestates.co.uk", password: "eSong789", company: "Crownstone Estates")
# 5
john = User.create!(user_name: "John Akachi", email: "john.akachi@harbourandheath.co.uk", password: "ImGreat1", company: "Harbour & Heath Properties")
puts "Created 8 users (3 admins, 5 agents)."

puts "Creating Chains..."
chain1 = Chain.create!(active: true, user: dom)
chain2 = Chain.create!(active: true, user: sarah)
chain3 = Chain.create!(active: true, user: toni)
puts "Created 3 active Chains."

puts "Creating Involved Parties..."
# seller only
# 1
frances = InvolvedParty.create!(first_name: "Frances", last_name: "Wright", email: "frances@wright.com", phone: "+44 20 7123 4567", contact_info: "10 Downing Street, London, SW1A 2AA", seller: true, buyer: false)
# 2
william = InvolvedParty.create!(first_name: "William", last_name: "Taylor", email: "w.taylor@btinternet.com", phone: "+44 113 496 0234", contact_info: "5 Castle Street, Sheffield, S1 5IJ", seller: true, buyer: false)
# 3
amelia = InvolvedParty.create!(first_name: "Amelia", last_name: "Johnson", email: "amelia.j@icloud.com", phone: "+44 7700 900890", contact_info: "33 Market Square, Nottingham, NG1 8OP", seller: true, buyer: false)

# buyer only
# 4
sophie = InvolvedParty.create!(first_name: "Sophie", last_name: "Brown", email: "sophie.b@hotmail.co.uk", phone: "+44 20 7946 0789", contact_info: "22 River Road, Bristol, BS1 4GH", seller: false, buyer: true)
# 5
harry = InvolvedParty.create!(first_name: "Harry", last_name: "Roberts", email: "h.roberts@live.co.uk", phone: "+44 121 496 0345", contact_info: "7 Bridge Lane, Newcastle, NE1 7MN", seller: false, buyer: true)
# 6
isabella = InvolvedParty.create!(first_name: "Isabella", last_name: "Jones", email: "isabella.jones@aol.co.uk", phone: "+44 7700 900901", contact_info: "55 Victoria Road, Glasgow, G1 1ST", seller: false, buyer: true)

# both
# 7
oliver = InvolvedParty.create!(first_name: "Oliver", last_name: "Thompson", email: "oliver.thompson@gmail.co.uk", phone: "+44 7700 900123", contact_info: "42 High Street, Manchester, M1 1AB", seller: true, buyer: true)
# 8
emma = InvolvedParty.create!(first_name: "Emma", last_name: "Davies", email: "e.davies@outlook.co.uk", phone: "+44 161 496 0123", contact_info: "15 Oak Avenue, Birmingham, B1 2CD", seller: true, buyer: true)
# 9
james = InvolvedParty.create!(first_name: "James", last_name: "Wilson", email: "j.wilson@yahoo.co.uk", phone: "+44 7700 900456", contact_info: "88 Park Lane, Leeds, LS1 3EF", seller: true, buyer: true)
# 10
charlotte = InvolvedParty.create!(first_name: "Charlotte", last_name: "Evans", email: "charlotte.evans@googlemail.com", phone: "+44 7700 900789", contact_info: "101 Queen Street, Liverpool, L1 6KL", seller: true, buyer: true)
# 11
george = InvolvedParty.create!(first_name: "George", last_name: "Smith", email: "g.smith@proton.me", phone: "+44 117 496 0456", contact_info: "12 Station Road, Cardiff, CF10 9QR", seller: true, buyer: true)
# 12
jack = InvolvedParty.create!(first_name: "Jack", last_name: "Williams", email: "jack.w@sky.com", phone: "+44 141 496 0567", contact_info: "9 Church Lane, Edinburgh, EH1 2UV", seller: true, buyer: true)
# 13
mia = InvolvedParty.create!(first_name: "Mia", last_name: "Davis", email: "mia.davis@fastmail.com", phone: "+44 7700 901012", contact_info: "18 Mill Road, Belfast, BT1 3WX", seller: true, buyer: true)
#14
liam = InvolvedParty.create!(first_name: "Liam", last_name: "Clark", email: "liam.clark@virgin.net", phone: "+44 7700 901123", contact_info: "41 Forest Drive, Norwich, NR1 6CD", seller: true, buyer: true)
# 15
harper = InvolvedParty.create!(first_name: "Harper", last_name: "Hall", email: "harper.hall@libero.it", phone: "+44 118 496 0901", contact_info: "30 Garden Close, Oxford, OX1 9IJ", seller: true, buyer: true)
# 16
noah = InvolvedParty.create!(first_name: "Noah", last_name: "Miller", email: "noah.miller@zoho.com", phone: "+44 29 2046 0678", contact_info: "64 Green Way, Swansea, SA1 4YZ", seller: true, buyer: true)
# 17
ava = InvolvedParty.create!(first_name: "Ava", last_name: "Harris", email: "ava.h@tiscali.co.uk", phone: "+44 191 496 0789", contact_info: "29 Hill Top, Sunderland, SR1 5AB", seller: true, buyer: true)
# 18
evelyn = InvolvedParty.create!(first_name: "Evelyn", last_name: "Lewis", email: "evelyn.lewis@talktalk.net", phone: "+44 1603 496 0890", contact_info: "13 Sea View, Brighton, BN1 7EF", seller: true, buyer: true)
# 19
mason = InvolvedParty.create!(first_name: "Mason", last_name: "Walker", email: "mason.w@orange.fr", phone: "+44 7700 901234", contact_info: "76 Valley Road, Reading, RG1 8GH", seller: true, buyer: true)
# 20
logan = InvolvedParty.create!(first_name: "Logan", last_name: "Allen", email: "logan.allen@alice.it", phone: "+44 7700 901345", contact_info: "52 Meadow Lane, Cambridge, CB1 0KL", seller: true, buyer: true)
# 21
arthur = InvolvedParty.create!(first_name: "Arthur", last_name: "Pemberton", email: "arthur.pemberton@btconnect.com", phone: "+44 7700 901456", contact_info: "8 Elm Grove, York, YO1 1MN", seller: true, buyer: true)
# 22
grace = InvolvedParty.create!(first_name: "Grace", last_name: "Fletcher", email: "grace.f@rocketmail.com", phone: "+44 1273 496 101", contact_info: "14 Beech Road, Hastings, TN34 2OP", seller: true, buyer: true)
# 23
theo = InvolvedParty.create!(first_name: "Theo", last_name: "Barnes", email: "theo.barnes@fastmail.fm", phone: "+44 7700 901567", contact_info: "27 Willow Close, Bath, BA1 3QR", seller: true, buyer: true)
# 24
lily = InvolvedParty.create!(first_name: "Lily", last_name: "Cooper", email: "lily.c@icloud.co.uk", phone: "+44 1865 496 212", contact_info: "9 Ash Tree Lane, Oxford, OX2 4ST", seller: true, buyer: true)
# 25
finn = InvolvedParty.create!(first_name: "Finn", last_name: "Reed", email: "finn.reed@proton.me", phone: "+44 7700 901678", contact_info: "45 Cedar Drive, Exeter, EX1 5UV", seller: true, buyer: true)
puts "Created  25 Involved Parties."


puts "Creating Properties..."
sellers = [frances, william, amelia, oliver, emma, james, charlotte, george, jack, mia, liam, harper, noah, ava, evelyn, mason, logan, arthur, grace, theo, lily, finn]
realtors = [sarah, toni, mark, emily, john]

# Link involved parties to agents
InvolvedParty.all.each_with_index do |party, idx|
  party.update!(user: realtors[idx % realtors.length])
end

property_data = [
  { house_number: "10", street: "Maple Drive", second_line: "", city: "London", post_code: "SW1A 1AA", sold: false },
  { house_number: "42", street: "Oak Avenue", second_line: "Flat 2", city: "Manchester", post_code: "M1 2AB", sold: false },
  { house_number: "8", street: "Cedar Lane", second_line: "", city: "Birmingham", post_code: "B1 3CD", sold: false },
  { house_number: "15", street: "Birch Road", second_line: "Unit 4", city: "Leeds", post_code: "LS1 4EF", sold: false },
  { house_number: "22", street: "Willow Close", second_line: "", city: "Bristol", post_code: "BS1 5GH", sold: false },
  { house_number: "5", street: "Elm Street", second_line: "", city: "Liverpool", post_code: "L1 6IJ", sold: false },
  { house_number: "33", street: "Pine Grove", second_line: "Appt 1", city: "Newcastle", post_code: "NE1 7KL", sold: false },
  { house_number: "77", street: "Ash Way", second_line: "", city: "Nottingham", post_code: "NG1 8MN", sold: false },
  { house_number: "12", street: "Holly Path", second_line: "", city: "Cardiff", post_code: "CF10 9OP", sold: false },
  { house_number: "99", street: "Rowan Court", second_line: "House B", city: "Glasgow", post_code: "G1 1QR", sold: false },
  { house_number: "6", street: "Sycamore Drive", second_line: "", city: "Edinburgh", post_code: "EH1 2ST", sold: false },
  { house_number: "18", street: "Poplar Road", second_line: "", city: "Belfast", post_code: "BT1 3UV", sold: false },
  { house_number: "45", street: "Chestnut Lane", second_line: "Top Floor", city: "Swansea", post_code: "SA1 4WX", sold: false },
  { house_number: "29", street: "Laurel Avenue", second_line: "", city: "Sunderland", post_code: "SR1 5YZ", sold: false },
  { house_number: "64", street: "Hawthorn Way", second_line: "", city: "Norwich", post_code: "NR1 6AB", sold: false },
  { house_number: "13", street: "Magnolia Close", second_line: "", city: "Brighton", post_code: "BN1 7CD", sold: true },  # Sold 1
  { house_number: "76", street: "Beech Road", second_line: "Flat 5", city: "Reading", post_code: "RG1 8EF", sold: true },  # Sold 2
  { house_number: "30", street: "Fir Tree Lane", second_line: "", city: "Oxford", post_code: "OX1 9GH", sold: true },  # Sold 3
  { house_number: "52", street: "Cypress Drive", second_line: "", city: "Cambridge", post_code: "CB1 0IJ", sold: true },  # Sold 4
  { house_number: "88", street: "Juniper Court", second_line: "Suite 1", city: "York", post_code: "YO1 1KL", sold: true }   # Sold 5
]

all_properties = [] # Initialize the array

property_data.each_with_index do |data, index|
  # Cycle through realtors (0-4) and sellers (0-21)
  realtor = realtors[index % 5]
  seller = sellers[index % sellers.length]
  # Photos live in public/images/properties/ (CC0 images, see CREDITS.txt there)
  photo_path = "/images/properties/property_#{index + 1}.jpg"

  # Create the property and push it to the array
  p = Property.create!(
    user_id: realtor.id,
    involved_party_id: seller.id,
    photos: photo_path,
    house_number: data[:house_number],
    street: data[:street],
    second_line_of_address: data[:second_line],
    city: data[:city],
    post_code: data[:post_code],
    sold: data[:sold]
  )

  all_properties << p # Save the object
end
puts "Created 20 Properties (5 sold)."

puts "Creating Transactions..."
chains = [chain1, chain2, chain3]
realtors = [sarah, toni, mark, emily, john]
buyers = [sophie, harry, isabella, oliver, emma, james, charlotte, george, jack, mia, liam, harper, noah, ava, evelyn, mason, logan, arthur, grace, theo, lily, finn]

# Split properties into two groups based on 'sold' status
unsold_properties = all_properties.select { |p| !p.sold }
sold_properties = all_properties.select { |p| p.sold }

transactions_to_create = []

# 1. Create 15 OPEN transactions for UNSOLD properties
15.times do |i|
  transactions_to_create << {
    chain_id: chains[i % chains.length].id,
    involved_party_id: buyers[i].id,
    property_id: unsold_properties[i].id,
    user_id: realtors[i % realtors.length].id,
    completed: false
  }
end

# 2. Create 5 COMPLETED transactions for SOLD properties
5.times do |i|
  transactions_to_create << {
    chain_id: chains[i % chains.length].id,
    involved_party_id: buyers[15 + i].id, # Continue cycling through buyers
    property_id: sold_properties[i].id,
    user_id: realtors[(15 + i) % realtors.length].id,
    completed: true
  }
end

# Execute creation
transactions_to_create.each do |data|
  Transaction.create!(
    chain_id: data[:chain_id],
    involved_party_id: data[:involved_party_id],
    property_id: data[:property_id],
    user_id: data[:user_id],
    completed: data[:completed]
  )
end
puts "Created 20 transactions (15 open, 5 completed)."
