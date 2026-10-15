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
dom = User.create!(user_name: "Dom", email: "dom@moveee.me", phone: "+44 20 7946 0001", password: "MoveeeAdmin123", company: "Moveee", admin: true)
joao = User.create!(user_name: "Joao", email: "joao@moveee.me", phone: "+44 20 7946 0002", password: "MoveeeAdmin123", company: "Moveee", admin: true)
sophia = User.create!(user_name: "Sophia", email: "sophia@moveee.me", phone: "+44 20 7946 0003", password: "MoveeeAdmin123", company: "Moveee", admin: true)

# 1
sarah = User.create!(user_name: "Sarah Rizzoli", email: "sarah.rizzoli@harbourandheath.co.uk", phone: "+44 20 7946 0101", password: "SaRi1234", company: "Harbour & Heath Properties")
#2
toni = User.create!(user_name: "Toni Martine", email: "t.martine@crownstoneestates.co.uk", phone: "+44 20 7946 0102", password: "Ton1Crown", company: "Crownstone Estates")
# 3
mark = User.create!(user_name: "Mark McBride", email: "mcbride.mark@thistleandthatch.co.uk", phone: "+44 20 7946 0103", password: "123Bride", company: "Thistle & Thatch Residential")
# 4
emily = User.create!(user_name: "Emily Song", email: "e.song@belgravesterling.co.uk", phone: "+44 20 7946 0104", password: "eSong789", company: "Belgrave & Sterling Estates")
# 5
john = User.create!(user_name: "John Akachi", email: "john.akachi@oakhavenfinch.co.uk", phone: "+44 20 7946 0105", password: "ImGreat1", company: "Oakhaven & Finch Estates")
puts "Created 8 users (3 admins, 5 agents from 5 different estate agencies)."

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
sellers = [
  emma, james, amelia, george, jack, mia, liam, harper,
  noah, ava, evelyn, mason, logan, arthur, grace,
  oliver, frances, william, theo, lily, finn, charlotte
]
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

today = Date.current

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

# 15 distinct open scenarios covering various dates and on/behind target statuses
open_scenarios = [
  # 1. Offer accepted 2 days ago (On track: due tomorrow)
  { days_ago: 2, stage: "offer_accepted", actual_offsets: {} },
  # 2. Offer accepted 8 days ago (Behind target: overdue by 5d)
  { days_ago: 8, stage: "offer_accepted", actual_offsets: {} },
  # 3. Solicitors instructed 10 days ago (On track: stage 1 approved in 2d [ahead])
  { days_ago: 10, stage: "solicitors_instructed", actual_offsets: { "offer_accepted" => 2 } },
  # 4. Solicitors instructed 24 days ago (Behind target: AML checks took long, overdue by 10d)
  { days_ago: 24, stage: "solicitors_instructed", actual_offsets: { "offer_accepted" => 3 } },
  # 5. Draft contracts 18 days ago (On track / Ahead: stages 1 & 2 done swiftly)
  { days_ago: 18, stage: "draft_contract_pack", actual_offsets: { "offer_accepted" => 2, "solicitors_instructed" => 10 } },
  # 6. Draft contracts 38 days ago (Behind target: TA7 / leasehold pack delayed, overdue by 17d)
  { days_ago: 38, stage: "draft_contract_pack", actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 14 } },
  # 7. Searches & enquiries 35 days ago (On track: searches progressing normally, due in 7d)
  { days_ago: 35, stage: "searches_and_enquiries", actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 12, "draft_contract_pack" => 19 } },
  # 8. Searches & enquiries 55 days ago (Behind target: council search backlog, overdue by 13d)
  { days_ago: 55, stage: "searches_and_enquiries", actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 14, "draft_contract_pack" => 21 } },
  # 9. Survey & mortgage 50 days ago (On track: valuation done, offer expected in 6d)
  { days_ago: 50, stage: "survey_and_mortgage", actual_offsets: { "offer_accepted" => 2, "solicitors_instructed" => 12, "draft_contract_pack" => 20, "searches_and_enquiries" => 40 } },
  # 10. Survey & mortgage 70 days ago (Behind target: down-valuation renegotiation, overdue by 14d)
  { days_ago: 70, stage: "survey_and_mortgage", actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 14, "draft_contract_pack" => 21, "searches_and_enquiries" => 42 } },
  # 11. Enquiries resolved / contracts signed 65 days ago (On track: contracts out for signature, due in 5d)
  { days_ago: 65, stage: "enquiries_resolved", actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 13, "draft_contract_pack" => 21, "searches_and_enquiries" => 41, "survey_and_mortgage" => 55 } },
  # 12. Enquiries resolved / contracts signed 88 days ago (Behind target: missing FENSA/building regs, overdue by 18d)
  { days_ago: 88, stage: "enquiries_resolved", actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 14, "draft_contract_pack" => 22, "searches_and_enquiries" => 44, "survey_and_mortgage" => 60 } },
  # 13. Exchange of contracts 74 days ago (On track: authority to exchange in place, due in 3d)
  { days_ago: 74, stage: "exchange_of_contracts", actual_offsets: { "offer_accepted" => 2, "solicitors_instructed" => 12, "draft_contract_pack" => 20, "searches_and_enquiries" => 40, "survey_and_mortgage" => 54, "enquiries_resolved" => 68 } },
  # 14. Exchange of contracts 96 days ago (Behind target: chain link deposit delay, overdue by 19d)
  { days_ago: 96, stage: "exchange_of_contracts", actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 15, "draft_contract_pack" => 25, "searches_and_enquiries" => 48, "survey_and_mortgage" => 62, "enquiries_resolved" => 78 } },
  # 15. Searches & enquiries 45 days ago (Mixed: early ahead, then delayed, now 3d overdue)
  { days_ago: 45, stage: "searches_and_enquiries", actual_offsets: { "offer_accepted" => 1, "solicitors_instructed" => 20, "draft_contract_pack" => 23 } }
]

# 5 completed scenarios showing early, on-target, and delayed completions
completed_scenarios = [
  # 16. Completed 12 days ahead of target (Target 84d, Actual 72d)
  { days_ago: 92, actual_comp_days: 72, actual_offsets: { "offer_accepted" => 2, "solicitors_instructed" => 10, "draft_contract_pack" => 17, "searches_and_enquiries" => 35, "survey_and_mortgage" => 48, "enquiries_resolved" => 60, "exchange_of_contracts" => 66, "completion" => 72 } },
  # 17. Completed exactly on target (Target 84d, Actual 84d)
  { days_ago: 100, actual_comp_days: 84, actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 14, "draft_contract_pack" => 21, "searches_and_enquiries" => 42, "survey_and_mortgage" => 56, "enquiries_resolved" => 70, "exchange_of_contracts" => 77, "completion" => 84 } },
  # 18. Completed 16 days behind target (Target 84d, Actual 100d - search and mortgage delay)
  { days_ago: 116, actual_comp_days: 100, actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 14, "draft_contract_pack" => 22, "searches_and_enquiries" => 52, "survey_and_mortgage" => 70, "enquiries_resolved" => 86, "exchange_of_contracts" => 93, "completion" => 100 } },
  # 19. Completed 35 days behind target (Target 84d, Actual 119d - chain & probate delay)
  { days_ago: 135, actual_comp_days: 119, actual_offsets: { "offer_accepted" => 3, "solicitors_instructed" => 16, "draft_contract_pack" => 28, "searches_and_enquiries" => 60, "survey_and_mortgage" => 80, "enquiries_resolved" => 102, "exchange_of_contracts" => 110, "completion" => 119 } },
  # 20. Completed 4 days ahead of target (Target 84d, Actual 80d)
  { days_ago: 88, actual_comp_days: 80, actual_offsets: { "offer_accepted" => 2, "solicitors_instructed" => 12, "draft_contract_pack" => 19, "searches_and_enquiries" => 38, "survey_and_mortgage" => 52, "enquiries_resolved" => 66, "exchange_of_contracts" => 74, "completion" => 80 } }
]

# 1. Create 15 OPEN transactions with staggered dates and milestone approvals
15.times do |i|
  scenario = open_scenarios[i]
  start_time = (today - scenario[:days_ago].days).beginning_of_day + 10.hours
  start_d = start_time.to_date
  est_comp_d = start_d + 84.days
  s_dates = build_stage_dates(start_d, est_comp_d, scenario[:stage], scenario[:actual_offsets])

  # Deliberate chaining for Chain 2 (FTB Harry -> Emma -> James -> Amelia leaving market)
  # and Chain 3 (Charlotte has home to sell -> George buying onward)
  target_chain = if i < 3
                   chain2
                 else
                   chain3
                 end

  target_buyer = case i
                 when 0 then harry      # FTB (buyer only)
                 when 1 then emma       # Links from Property 1 sale
                 when 2 then james      # Links from Property 2 sale
                 when 3 then charlotte  # Has home to sell (not FTB)
                 else buyers[i]
                 end

  Transaction.create!(
    chain_id: target_chain.id,
    involved_party_id: target_buyer.id,
    property_id: unsold_properties[i].id,
    user_id: realtors[i % realtors.length].id,
    completed: false,
    legal_stage: scenario[:stage],
    created_at: start_time,
    updated_at: start_time + [scenario[:days_ago] - 1, 1].max.days,
    estimated_completion_date: est_comp_d,
    actual_completion_date: nil,
    stage_dates: s_dates
  )
end

# 2. Create 5 COMPLETED transactions for SOLD properties with realistic completion dates
5.times do |i|
  scenario = completed_scenarios[i]
  start_time = (today - scenario[:days_ago].days).beginning_of_day + 9.hours
  start_d = start_time.to_date
  est_comp_d = start_d + 84.days
  act_comp_d = start_d + scenario[:actual_comp_days].days
  s_dates = build_stage_dates(start_d, est_comp_d, "completion", scenario[:actual_offsets])

  # Deliberate chaining for Chain 1: Sophie (FTB) -> Oliver -> Frances (leaving market)
  target_chain = (i < 2) ? chain1 : chain3
  target_buyer = case i
                 when 0 then sophie     # FTB (buyer only)
                 when 1 then oliver     # Links from Property 16 sale
                 else buyers[15 + i]
                 end

  Transaction.create!(
    chain_id: target_chain.id,
    involved_party_id: target_buyer.id,
    property_id: sold_properties[i].id,
    user_id: realtors[(15 + i) % realtors.length].id,
    completed: true,
    legal_stage: "completion",
    created_at: start_time,
    updated_at: act_comp_d.beginning_of_day + 14.hours,
    estimated_completion_date: est_comp_d,
    actual_completion_date: act_comp_d,
    stage_dates: s_dates
  )
end

Chain.find_each(&:sync_status!)

puts "Created 20 transactions with realistic UK conveyancing dates, boundary checks, and on/behind target approvals."
