# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require "open-uri"

puts "Purging previous attachments (including Cloudinary files)..."
ActiveStorage::Attachment.find_each(&:purge)
ActiveStorage::Blob.find_each(&:purge)

puts "Cleaning database..."
User.destroy_all
Chain.destroy_all
InvolvedParty.destroy_all
Transaction.destroy_all
Property.destroy_all

puts "Creating users..."
# Admin Users
dom = User.create!(user_name: "Dom", email: "dom@moveee.me", phone: "+44 20 7946 0001", password: "MoveeeAdmin123", company: "Moveee", admin: true)
joao = User.create!(user_name: "Joao", email: "joao@moveee.me", phone: "+44 20 7946 0002", password: "MoveeeAdmin123", company: "Moveee", admin: true)
sophia = User.create!(user_name: "Sophia", email: "sophia@moveee.me", phone: "+44 20 7946 0003", password: "MoveeeAdmin123", company: "Moveee", admin: true)

# 5 Cooperating Estate Agents from 5 distinct UK agencies
sarah = User.create!(user_name: "Sarah Rizzoli", email: "sarah.rizzoli@harbourandheath.co.uk", phone: "+44 20 7946 0312", password: "SaRi1234", company: "Harbour & Heath Properties")
toni = User.create!(user_name: "Toni Martine", email: "t.martine@crownstoneestates.co.uk", phone: "+44 20 7118 4407", password: "Ton1Crown", company: "Crownstone Estates")
mark = User.create!(user_name: "Mark McBride", email: "mcbride.mark@thistleandthatch.co.uk", phone: "+44 20 7946 0103", password: "123Bride", company: "Thistle & Thatch Residential")
emily = User.create!(user_name: "Emily Song", email: "e.song@belgravesterling.co.uk", phone: "+44 20 7932 5580", password: "eSong789", company: "Belgrave & Sterling Estates")
john = User.create!(user_name: "John Akachi", email: "john.akachi@oakhavenfinch.co.uk", phone: "+44 1892 447 130", password: "ImGreat1", company: "Oakhaven & Finch Estates")
puts "Created 8 users (3 admins, 5 agents from 5 different UK estate agencies)."

puts "Attaching agent avatars..."
# Admins are left without avatars so they can upload their own.
{
  sarah => "https://randomuser.me/api/portraits/women/44.jpg",
  toni => "https://randomuser.me/api/portraits/women/68.jpg",
  mark => "https://randomuser.me/api/portraits/men/32.jpg",
  emily => "https://randomuser.me/api/portraits/women/90.jpg",
  john => "https://randomuser.me/api/portraits/men/75.jpg"
}.each do |user, url|
  file = URI.parse(url).open
  user.avatar.attach(io: file, filename: "#{user.user_name.parameterize}.jpg", content_type: "image/jpeg")
rescue StandardError => e
  puts "  Skipped avatar for #{user.user_name}: #{e.message}"
end

puts "Creating Involved Parties..."
# 1. First-Time Buyers (FTB: buyer only, no home to sell) -> Closed Bottom
sophie = InvolvedParty.create!(first_name: "Sophie", last_name: "Brown", email: "sophie.b@hotmail.co.uk", phone: "+44 20 7946 0789", contact_info: "22 River Road, Bristol, BS1 4GH", seller: false, buyer: true)
harry = InvolvedParty.create!(first_name: "Harry", last_name: "Roberts", email: "h.roberts@live.co.uk", phone: "+44 121 496 0345", contact_info: "7 Bridge Lane, Newcastle, NE1 7MN", seller: false, buyer: true)
isabella = InvolvedParty.create!(first_name: "Isabella", last_name: "Jones", email: "isabella.jones@aol.co.uk", phone: "+44 7700 900901", contact_info: "55 Victoria Road, Glasgow, G1 1ST", seller: false, buyer: true)
liam = InvolvedParty.create!(first_name: "Liam", last_name: "Clark", email: "liam.clark@virgin.net", phone: "+44 7700 901123", contact_info: "41 Forest Drive, Norwich, NR1 6CD", seller: false, buyer: true)
noah = InvolvedParty.create!(first_name: "Noah", last_name: "Miller", email: "noah.miller@zoho.com", phone: "+44 29 2046 0678", contact_info: "64 Green Way, Swansea, SA1 4YZ", seller: false, buyer: true)
grace = InvolvedParty.create!(first_name: "Grace", last_name: "Fletcher", email: "grace.f@rocketmail.com", phone: "+44 1273 496 101", contact_info: "14 Beech Road, Hastings, TN34 2OP", seller: false, buyer: true)
poppy = InvolvedParty.create!(first_name: "Poppy", last_name: "Walsh", email: "poppy.walsh@gmail.com", phone: "+44 7700 900482", contact_info: "9 Orchard Close, Leeds, LS1 4AB", seller: false, buyer: true)

# 2. Leaving the Property Market (seller only, no onward purchase / probate / emigration) -> Closed Top
frances = InvolvedParty.create!(first_name: "Frances", last_name: "Wright", email: "frances@wright.com", phone: "+44 20 7123 4567", contact_info: "10 Downing Street, London, SW1A 2AA", seller: true, buyer: false, onward_purchase: "leaving_market")
amelia = InvolvedParty.create!(first_name: "Amelia", last_name: "Johnson", email: "amelia.j@icloud.com", phone: "+44 7700 900890", contact_info: "33 Market Square, Nottingham, NG1 8OP", seller: true, buyer: false, onward_purchase: "leaving_market")
william = InvolvedParty.create!(first_name: "William", last_name: "Taylor", email: "w.taylor@btinternet.com", phone: "+44 113 496 0234", contact_info: "5 Castle Street, Sheffield, S1 5IJ", seller: true, buyer: false, onward_purchase: "leaving_market")
finn = InvolvedParty.create!(first_name: "Finn", last_name: "Reed", email: "finn.reed@proton.me", phone: "+44 7700 901678", contact_info: "45 Cedar Drive, Exeter, EX1 5UV", seller: true, buyer: false, onward_purchase: "leaving_market")
arthur = InvolvedParty.create!(first_name: "Arthur", last_name: "Pemberton", email: "arthur.pemberton@btconnect.com", phone: "+44 7700 901456", contact_info: "8 Elm Grove, York, YO1 1MN", seller: true, buyer: false, onward_purchase: "leaving_market")

# 3. Chained Mover Clients (both seller & buyer: selling one property and buying another)
oliver = InvolvedParty.create!(first_name: "Oliver", last_name: "Thompson", email: "oliver.thompson@gmail.co.uk", phone: "+44 7700 900123", contact_info: "42 High Street, Manchester, M1 1AB", seller: true, buyer: true, onward_purchase: "buying")
emma = InvolvedParty.create!(first_name: "Emma", last_name: "Davies", email: "e.davies@outlook.co.uk", phone: "+44 161 496 0123", contact_info: "15 Oak Avenue, Birmingham, B1 2CD", seller: true, buyer: true, onward_purchase: "buying")
james = InvolvedParty.create!(first_name: "James", last_name: "Wilson", email: "j.wilson@yahoo.co.uk", phone: "+44 7700 900456", contact_info: "88 Park Lane, Leeds, LS1 3EF", seller: true, buyer: true, onward_purchase: "buying")
charlotte = InvolvedParty.create!(first_name: "Charlotte", last_name: "Evans", email: "charlotte.evans@googlemail.com", phone: "+44 7700 900789", contact_info: "101 Queen Street, Liverpool, L1 6KL", seller: true, buyer: true, onward_purchase: "buying")
george = InvolvedParty.create!(first_name: "George", last_name: "Smith", email: "g.smith@proton.me", phone: "+44 117 496 0456", contact_info: "12 Station Road, Cardiff, CF10 9QR", seller: true, buyer: true, onward_purchase: "buying")
jack = InvolvedParty.create!(first_name: "Jack", last_name: "Williams", email: "jack.w@sky.com", phone: "+44 141 496 0567", contact_info: "9 Church Lane, Edinburgh, EH1 2UV", seller: true, buyer: true, onward_purchase: "buying")
mia = InvolvedParty.create!(first_name: "Mia", last_name: "Davis", email: "mia.davis@fastmail.com", phone: "+44 7700 901012", contact_info: "18 Mill Road, Belfast, BT1 3WX", seller: true, buyer: true, onward_purchase: "buying")
harper = InvolvedParty.create!(first_name: "Harper", last_name: "Hall", email: "harper.hall@libero.it", phone: "+44 118 496 0901", contact_info: "30 Garden Close, Oxford, OX1 9IJ", seller: true, buyer: true, onward_purchase: "buying")
ava = InvolvedParty.create!(first_name: "Ava", last_name: "Harris", email: "ava.h@tiscali.co.uk", phone: "+44 191 496 0789", contact_info: "29 Hill Top, Sunderland, SR1 5AB", seller: true, buyer: true, onward_purchase: "buying")
evelyn = InvolvedParty.create!(first_name: "Evelyn", last_name: "Lewis", email: "evelyn.lewis@talktalk.net", phone: "+44 1603 496 0890", contact_info: "13 Sea View, Brighton, BN1 7EF", seller: true, buyer: true, onward_purchase: "buying")
mason = InvolvedParty.create!(first_name: "Mason", last_name: "Walker", email: "mason.w@orange.fr", phone: "+44 7700 901234", contact_info: "76 Valley Road, Reading, RG1 8GH", seller: true, buyer: true, onward_purchase: "buying")
logan = InvolvedParty.create!(first_name: "Logan", last_name: "Allen", email: "logan.allen@alice.it", phone: "+44 7700 901345", contact_info: "52 Meadow Lane, Cambridge, CB1 0KL", seller: true, buyer: true, onward_purchase: "buying")
theo = InvolvedParty.create!(first_name: "Theo", last_name: "Barnes", email: "theo.barnes@fastmail.fm", phone: "+44 7700 901567", contact_info: "27 Willow Close, Bath, BA1 3QR", seller: true, buyer: true, onward_purchase: "buying")
lily = InvolvedParty.create!(first_name: "Lily", last_name: "Cooper", email: "lily.c@icloud.co.uk", phone: "+44 1865 496 212", contact_info: "9 Ash Tree Lane, Oxford, OX2 4ST", seller: true, buyer: true, onward_purchase: "buying")

# Assign FTB buyers to their managing agent
sophie.update!(user: toni) # Sophie is deliberately left without a purchase: she closes the chain in the demo
poppy.update!(user: toni)
harry.update!(user: sarah)
isabella.update!(user: emily)
liam.update!(user: mark)
noah.update!(user: john)
grace.update!(user: mark)
puts "Created 25 Involved Parties (6 FTBs, 5 Market Exits, 14 Movers)."

puts "Creating Properties..."
property_configs = [
  # Chain 2 properties (Unsold 1-3)
  { num: "10", street: "Maple Drive", second: "", city: "London", post_code: "SW1A 1AA", sold: false, user: sarah, seller: emma },
  { num: "42", street: "Oak Avenue", second: "Flat 2", city: "Manchester", post_code: "M1 2AB", sold: false, user: toni, seller: james },
  { num: "8", street: "Cedar Lane", second: "", city: "Birmingham", post_code: "B1 3CD", sold: false, user: mark, seller: amelia },
  # Chain 3 properties (Stalled Leasehold: Unsold 4-5)
  { num: "15", street: "Birch Road", second: "Flat 4", city: "Leeds", post_code: "LS1 4EF", sold: false, user: emily, seller: evelyn },
  { num: "22", street: "Willow Close", second: "", city: "Bristol", post_code: "BS1 5GH", sold: false, user: john, seller: william },
  # Chain 4 properties (Open Bottom: Unsold 6-7)
  { num: "5", street: "Elm Street", second: "", city: "Liverpool", post_code: "L1 6IJ", sold: false, user: sarah, seller: george },
  { num: "33", street: "Pine Grove", second: "Appt 1", city: "Newcastle", post_code: "NE1 7KL", sold: false, user: toni, seller: arthur },
  # Chain 5 properties (Open Top: Unsold 8-9)
  { num: "77", street: "Ash Way", second: "", city: "Nottingham", post_code: "NG1 8MN", sold: false, user: mark, seller: jack },
  { num: "12", street: "Holly Path", second: "", city: "Cardiff", post_code: "CF10 9OP", sold: false, user: emily, seller: mia },
  # Merger Pair properties (Chain 6 & 7: Unsold 10-12)
  { num: "99", street: "Rowan Court", second: "House B", city: "Glasgow", post_code: "G1 1QR", sold: false, user: john, seller: harper },
  { num: "6", street: "Sycamore Drive", second: "", city: "Edinburgh", post_code: "EH1 2ST", sold: false, user: sarah, seller: logan },
  { num: "18", street: "Poplar Road", second: "", city: "Belfast", post_code: "BT1 3UV", sold: false, user: toni, seller: finn },
  # Standalone direct deal (Unsold 13)
  { num: "45", street: "Chestnut Lane", second: "Top Floor", city: "Swansea", post_code: "SA1 4WX", sold: false, user: mark, seller: frances },
  # Additional active listings (Unsold 14-16)
  { num: "29", street: "Laurel Avenue", second: "", city: "Sunderland", post_code: "SR1 5YZ", sold: false, user: emily, seller: ava },
  { num: "64", street: "Hawthorn Way", second: "", city: "Norwich", post_code: "NR1 6AB", sold: false, user: john, seller: mason },
  { num: "27", street: "Orchard Road", second: "", city: "Bath", post_code: "BA1 3QR", sold: false, user: sarah, seller: theo },
  # Chain 1 Completed Properties (Sold 17-18)
  { num: "13", street: "Magnolia Close", second: "", city: "Brighton", post_code: "BN1 7CD", sold: true, user: toni, seller: oliver },
  { num: "76", street: "Beech Road", second: "Flat 5", city: "Reading", post_code: "RG1 8EF", sold: true, user: mark, seller: frances },
  # Additional Sold Properties (Sold 19-22)
  { num: "30", street: "Fir Tree Lane", second: "", city: "Oxford", post_code: "OX1 9GH", sold: true, user: emily, seller: charlotte },
  { num: "52", street: "Cypress Drive", second: "", city: "Cambridge", post_code: "CB1 0IJ", sold: true, user: john, seller: lily },
  { num: "88", street: "Juniper Court", second: "Suite 1", city: "York", post_code: "YO1 1KL", sold: true, user: sarah, seller: emma },
  { num: "44", street: "Primrose Hill", second: "Garden Apt", city: "London", post_code: "NW3 3AA", sold: true, user: toni, seller: james }
]

properties = []
property_configs.each_with_index do |cfg, index|
  cfg[:seller].update!(user: cfg[:user]) if cfg[:seller].user.nil? || cfg[:seller].user != cfg[:user]
  photo_path = Rails.root.join("public/images/properties/property_#{(index % 17) + 1}.jpg")
  p = Property.new(
    user: cfg[:user],
    involved_party: cfg[:seller],
    house_number: cfg[:num],
    street: cfg[:street],
    second_line_of_address: cfg[:second],
    city: cfg[:city],
    post_code: cfg[:post_code],
    sold: cfg[:sold]
  )
  p.photo.attach(io: File.open(photo_path), filename: photo_path.basename.to_s, content_type: "image/jpeg")
  p.save!
  properties << p
end
puts "Created #{properties.size} Properties (#{properties.count(&:sold)} sold, #{properties.count { |p| !p.sold }} active)."

# Helper to generate granular stage milestone dates
def build_stage_dates(start_date, target_comp_date, current_stage, actual_offsets = {})
  span = [target_comp_date - start_date, 7].max.to_f
  dates = {}
  curr_idx = Transaction::LEGAL_STAGE_DEFINITIONS.dig(current_stage, :index) || 1

  Transaction::LEGAL_STAGES.each do |stg|
    s_idx = Transaction::LEGAL_STAGE_DEFINITIONS[stg][:index]
    default_days = Transaction::STAGE_DEFAULT_OFFSETS[stg]
    est_date = start_date + ((default_days / 84.0) * span).round.days

    act_date = nil
    if s_idx < curr_idx || (current_stage == "completion" && s_idx == 8)
      act_offset = actual_offsets[stg] || default_days
      act_date = start_date + act_offset.days
    end

    dates[stg] = {
      "estimated_date" => est_date.to_s,
      "actual_date" => act_date&.to_s
    }
  end
  dates
end

today = Date.current

puts "Creating Themed Chains & Transactions..."

# -------------------------------------------------------------------------------------------------
# SCENARIO 1: Completed Chain (Both Ends Closed & Fully Completed)
# Structure: Poppy (FTB) -> Oliver -> Frances (Leaving market). Both transactions completed.
# -------------------------------------------------------------------------------------------------
chain1 = Chain.create!(user: sarah, active: true)

# Deal 1: Poppy buys Property 17 from Oliver (Completed 12d ahead)
start_d1 = today - 92.days
comp_d1 = start_d1 + 72.days
Transaction.create!(
  chain: chain1,
  user: toni,
  involved_party: poppy,
  property: properties[16], # Magnolia Close (seller: Oliver)
  completed: true,
  legal_stage: "completion",
  created_at: start_d1.beginning_of_day + 9.hours,
  updated_at: comp_d1.beginning_of_day + 14.hours,
  estimated_completion_date: start_d1 + 84.days,
  actual_completion_date: comp_d1,
  stage_dates: build_stage_dates(start_d1, start_d1 + 84.days, "completion", {
    "offer_accepted" => 2, "solicitors_instructed" => 10, "draft_contract_pack" => 17,
    "searches_and_enquiries" => 35, "survey_and_mortgage" => 48, "enquiries_resolved" => 60,
    "exchange_of_contracts" => 66, "completion" => 72
  })
)

# Deal 2: Oliver buys Property 18 from Frances (Completed exactly on target)
start_d2 = today - 100.days
comp_d2 = start_d2 + 84.days
Transaction.create!(
  chain: chain1,
  user: mark,
  involved_party: oliver,
  property: properties[17], # Beech Road (seller: Frances, exit)
  completed: true,
  legal_stage: "completion",
  created_at: start_d2.beginning_of_day + 9.hours,
  updated_at: comp_d2.beginning_of_day + 15.hours,
  estimated_completion_date: start_d2 + 84.days,
  actual_completion_date: comp_d2,
  stage_dates: build_stage_dates(start_d2, start_d2 + 84.days, "completion", {
    "offer_accepted" => 3, "solicitors_instructed" => 14, "draft_contract_pack" => 21,
    "searches_and_enquiries" => 42, "survey_and_mortgage" => 56, "enquiries_resolved" => 70,
    "exchange_of_contracts" => 77, "completion" => 84
  })
)
chain1.sync_status!

# -------------------------------------------------------------------------------------------------
# SCENARIO 2: Smooth 3-Link Suburban Chain (Closed Ends, In Progress, On Track)
# Structure: Harry (FTB) -> Emma -> James -> Amelia (Leaving market)
# -------------------------------------------------------------------------------------------------
chain2 = Chain.create!(user: toni, active: true)

# Link 1: Harry buys Property 1 from Emma (Stage: Draft Contracts, 18d in, On Track)
s_d2_1 = today - 18.days
Transaction.create!(
  chain: chain2,
  user: sarah,
  involved_party: harry,
  property: properties[0], # Maple Drive (seller: Emma)
  completed: false,
  legal_stage: "draft_contract_pack",
  created_at: s_d2_1.beginning_of_day + 10.hours,
  updated_at: today - 1.day,
  estimated_completion_date: s_d2_1 + 84.days,
  stage_dates: build_stage_dates(s_d2_1, s_d2_1 + 84.days, "draft_contract_pack", { "offer_accepted" => 2, "solicitors_instructed" => 10 })
)

# Link 2: Emma buys Property 2 from James (Stage: Searches & Enquiries, 35d in, On Track)
s_d2_2 = today - 35.days
Transaction.create!(
  chain: chain2,
  user: toni,
  involved_party: emma,
  property: properties[1], # Oak Avenue (seller: James)
  completed: false,
  legal_stage: "searches_and_enquiries",
  created_at: s_d2_2.beginning_of_day + 10.hours,
  updated_at: today - 2.days,
  estimated_completion_date: s_d2_2 + 84.days,
  stage_dates: build_stage_dates(s_d2_2, s_d2_2 + 84.days, "searches_and_enquiries", { "offer_accepted" => 3, "solicitors_instructed" => 12, "draft_contract_pack" => 19 })
)

# Link 3: James buys Property 3 from Amelia (Stage: Survey & Mortgage, 50d in, On Track)
s_d2_3 = today - 50.days
Transaction.create!(
  chain: chain2,
  user: mark,
  involved_party: james,
  property: properties[2], # Cedar Lane (seller: Amelia, exit)
  completed: false,
  legal_stage: "survey_and_mortgage",
  created_at: s_d2_3.beginning_of_day + 10.hours,
  updated_at: today - 1.day,
  estimated_completion_date: s_d2_3 + 84.days,
  stage_dates: build_stage_dates(s_d2_3, s_d2_3 + 84.days, "survey_and_mortgage", { "offer_accepted" => 2, "solicitors_instructed" => 12, "draft_contract_pack" => 20, "searches_and_enquiries" => 40 })
)
chain2.sync_status!

# -------------------------------------------------------------------------------------------------
# SCENARIO 3: Stalled Leasehold Chain (Severe Delay / Overdue Warning Pill)
# Structure: Isabella (FTB) -> Evelyn -> William (Leaving market)
# Link 1 has leasehold pack / local authority delay (+18d overdue on searches & enquiries)
# -------------------------------------------------------------------------------------------------
chain3 = Chain.create!(user: mark, active: true)

# Link 1: Isabella buys Property 4 from Evelyn (Overdue: +18d behind on searches)
s_d3_1 = today - 60.days
Transaction.create!(
  chain: chain3,
  user: emily,
  involved_party: isabella,
  property: properties[3], # Birch Road flat (seller: Evelyn)
  completed: false,
  legal_stage: "searches_and_enquiries",
  created_at: s_d3_1.beginning_of_day + 10.hours,
  updated_at: today - 1.day,
  estimated_completion_date: s_d3_1 + 84.days,
  stage_dates: build_stage_dates(s_d3_1, s_d3_1 + 84.days, "searches_and_enquiries", { "offer_accepted" => 3, "solicitors_instructed" => 14, "draft_contract_pack" => 21 })
)

# Link 2: Evelyn buys Property 5 from William (Waiting on Link 1)
s_d3_2 = today - 14.days
Transaction.create!(
  chain: chain3,
  user: john,
  involved_party: evelyn,
  property: properties[4], # Willow Close (seller: William, exit)
  completed: false,
  legal_stage: "solicitors_instructed",
  created_at: s_d3_2.beginning_of_day + 10.hours,
  updated_at: today - 2.days,
  estimated_completion_date: s_d3_2 + 84.days,
  stage_dates: build_stage_dates(s_d3_2, s_d3_2 + 84.days, "solicitors_instructed", { "offer_accepted" => 3 })
)
chain3.sync_status!

# -------------------------------------------------------------------------------------------------
# SCENARIO 4: Open Bottom Chain (Missing First-Time Buyer)
# Structure: Charlotte (has home to sell) -> George -> Arthur (Leaving market)
# The chain cannot complete until Charlotte finds a buyer for her home.
# -------------------------------------------------------------------------------------------------
chain4 = Chain.create!(user: emily, active: true)

# Link 1: Charlotte buys Property 6 from George (Charlotte has home to sell)
s_d4_1 = today - 8.days
Transaction.create!(
  chain: chain4,
  user: sarah,
  involved_party: charlotte,
  property: properties[5], # Elm Street (seller: George)
  completed: false,
  legal_stage: "offer_accepted",
  created_at: s_d4_1.beginning_of_day + 10.hours,
  updated_at: today - 1.day,
  estimated_completion_date: s_d4_1 + 84.days,
  stage_dates: build_stage_dates(s_d4_1, s_d4_1 + 84.days, "offer_accepted", {})
)

# Link 2: George buys Property 7 from Arthur (Arthur leaving market)
s_d4_2 = today - 22.days
Transaction.create!(
  chain: chain4,
  user: toni,
  involved_party: george,
  property: properties[6], # Pine Grove (seller: Arthur, exit)
  completed: false,
  legal_stage: "draft_contract_pack",
  created_at: s_d4_2.beginning_of_day + 10.hours,
  updated_at: today - 3.days,
  estimated_completion_date: s_d4_2 + 84.days,
  stage_dates: build_stage_dates(s_d4_2, s_d4_2 + 84.days, "draft_contract_pack", { "offer_accepted" => 3, "solicitors_instructed" => 14 })
)
chain4.sync_status!

# -------------------------------------------------------------------------------------------------
# SCENARIO 5: Open Top Chain (Missing Market Exit / Vendor Buying Onward)
# Structure: Liam (FTB) -> Jack -> Mia (actively looking for onward property)
# The chain cannot complete until Mia agrees an offer on an onward property.
# -------------------------------------------------------------------------------------------------
chain5 = Chain.create!(user: john, active: true)

# Link 1: Liam (FTB) buys Property 8 from Jack
s_d5_1 = today - 16.days
Transaction.create!(
  chain: chain5,
  user: mark,
  involved_party: liam,
  property: properties[7], # Ash Way (seller: Jack)
  completed: false,
  legal_stage: "solicitors_instructed",
  created_at: s_d5_1.beginning_of_day + 10.hours,
  updated_at: today - 2.days,
  estimated_completion_date: s_d5_1 + 84.days,
  stage_dates: build_stage_dates(s_d5_1, s_d5_1 + 84.days, "solicitors_instructed", { "offer_accepted" => 2 })
)

# Link 2: Jack buys Property 9 from Mia (Mia is buying onward, not under offer yet)
s_d5_2 = today - 2.days
Transaction.create!(
  chain: chain5,
  user: emily,
  involved_party: jack,
  property: properties[8], # Holly Path (seller: Mia, buying onward)
  completed: false,
  legal_stage: "offer_accepted",
  created_at: s_d5_2.beginning_of_day + 10.hours,
  updated_at: today,
  estimated_completion_date: s_d5_2 + 84.days,
  stage_dates: build_stage_dates(s_d5_2, s_d5_2 + 84.days, "offer_accepted", {})
)
chain5.sync_status!

# -------------------------------------------------------------------------------------------------
# SCENARIOS 6 & 7: The Merger Pair (Ready to test 'Merge Chain' in UI!)
# Chain 6: Noah (FTB) -> Harper (selling Prop 10)
# Chain 7: Harper (buying Prop 11) -> Logan -> Finn (Exit, Prop 12)
# Harper connects both chains. Merging them produces a unified 3-link chain under lowest ID!
# -------------------------------------------------------------------------------------------------
chain6 = Chain.create!(user: sarah, active: true)
s_d6 = today - 42.days
Transaction.create!(
  chain: chain6,
  user: john,
  involved_party: noah,
  property: properties[9], # Rowan Court (seller: Harper)
  completed: false,
  legal_stage: "searches_and_enquiries",
  created_at: s_d6.beginning_of_day + 10.hours,
  updated_at: today - 1.day,
  estimated_completion_date: s_d6 + 84.days,
  stage_dates: build_stage_dates(s_d6, s_d6 + 84.days, "searches_and_enquiries", { "offer_accepted" => 3, "solicitors_instructed" => 12, "draft_contract_pack" => 20 })
)
chain6.sync_status!

chain7 = Chain.create!(user: mark, active: true)
s_d7_1 = today - 24.days
Transaction.create!(
  chain: chain7,
  user: sarah,
  involved_party: harper,
  property: properties[10], # Sycamore Drive (seller: Logan)
  completed: false,
  legal_stage: "draft_contract_pack",
  created_at: s_d7_1.beginning_of_day + 10.hours,
  updated_at: today - 2.days,
  estimated_completion_date: s_d7_1 + 84.days,
  stage_dates: build_stage_dates(s_d7_1, s_d7_1 + 84.days, "draft_contract_pack", { "offer_accepted" => 2, "solicitors_instructed" => 10 })
)

s_d7_2 = today - 12.days
Transaction.create!(
  chain: chain7,
  user: toni,
  involved_party: logan,
  property: properties[11], # Poplar Road (seller: Finn, exit)
  completed: false,
  legal_stage: "solicitors_instructed",
  created_at: s_d7_2.beginning_of_day + 10.hours,
  updated_at: today - 1.day,
  estimated_completion_date: s_d7_2 + 84.days,
  stage_dates: build_stage_dates(s_d7_2, s_d7_2 + 84.days, "solicitors_instructed", { "offer_accepted" => 3 })
)
chain7.sync_status!

# -------------------------------------------------------------------------------------------------
# SCENARIO 8: Direct Chain-Free Deal (1 Link, No Chain on Either Side)
# Grace (FTB) buys Property 13 directly from Frances (Probate / Market Exit)
# -------------------------------------------------------------------------------------------------
chain8 = Chain.create!(user: mark, active: true)
s_d8 = today - 74.days
Transaction.create!(
  chain: chain8,
  user: mark,
  involved_party: grace,
  property: properties[12], # Chestnut Lane (seller: Frances, exit)
  completed: false,
  legal_stage: "exchange_of_contracts",
  created_at: s_d8.beginning_of_day + 10.hours,
  updated_at: today - 1.day,
  estimated_completion_date: s_d8 + 84.days,
  stage_dates: build_stage_dates(s_d8, s_d8 + 84.days, "exchange_of_contracts", {
    "offer_accepted" => 2, "solicitors_instructed" => 12, "draft_contract_pack" => 20,
    "searches_and_enquiries" => 40, "survey_and_mortgage" => 54, "enquiries_resolved" => 68
  })
)
chain8.sync_status!

# -------------------------------------------------------------------------------------------------
# Additional Completed Transactions for Sold Properties (Prop 19 to 22)
# Demonstrates behind target (+16d, +35d) and ahead of target (4d ahead) completions
# -------------------------------------------------------------------------------------------------
sold_scenarios = [
  # Completed 16 days behind target (Target 84d, Actual 100d)
  { days_ago: 116, act_days: 100, party: ava, prop: properties[18], user: emily },
  # Completed 35 days behind target (Target 84d, Actual 119d)
  { days_ago: 135, act_days: 119, party: mason, prop: properties[19], user: john },
  # Completed 4 days ahead of target (Target 84d, Actual 80d)
  { days_ago: 88, act_days: 80, party: theo, prop: properties[20], user: sarah },
  # Completed on target (Target 84d, Actual 84d)
  { days_ago: 95, act_days: 84, party: lily, prop: properties[21], user: toni }
]

sold_scenarios.each do |sc|
  st_d = today - sc[:days_ago].days
  act_comp = st_d + sc[:act_days].days
  est_comp = st_d + 84.days

  # Allow transaction creation to auto-create each completed deal's chain!
  Transaction.create!(
    user: sc[:user],
    involved_party: sc[:party],
    property: sc[:prop],
    completed: true,
    legal_stage: "completion",
    created_at: st_d.beginning_of_day + 9.hours,
    updated_at: act_comp.beginning_of_day + 14.hours,
    estimated_completion_date: est_comp,
    actual_completion_date: act_comp,
    stage_dates: build_stage_dates(st_d, est_comp, "completion", {
      "offer_accepted" => 3, "solicitors_instructed" => 14, "draft_contract_pack" => 22,
      "searches_and_enquiries" => 45, "survey_and_mortgage" => 60, "enquiries_resolved" => 75,
      "exchange_of_contracts" => 80, "completion" => sc[:act_days]
    })
  )
end

# Final synchronization of all chains
Chain.find_each(&:sync_status!)

puts "Successfully seeded #{Chain.count} chains and #{Transaction.count} transactions across #{Property.count} properties!"
puts "Themed Scenarios Active:"
puts " - Chain ##{chain1.id}: Completed Chain (FTB -> Mover -> Exit, Completed)"
puts " - Chain ##{chain2.id}: Smooth 3-Link Suburban Chain (In Progress, Both Ends Closed)"
puts " - Chain ##{chain3.id}: Stalled Leasehold Chain (+18d Overdue Warning on Searches)"
puts " - Chain ##{chain4.id}: Open Bottom Chain (Missing FTB, Charlotte has home to sell)"
puts " - Chain ##{chain5.id}: Open Top Chain (Missing Exit, Mia buying onward)"
puts " - Chain ##{chain6.id} & Chain ##{chain7.id}: Merger Pair (Ready to test 'Merge Chain' under lowest ID)"
puts " - Chain ##{chain8.id}: Direct Chain-Free Deal (1 Link, Both Ends Closed)"
