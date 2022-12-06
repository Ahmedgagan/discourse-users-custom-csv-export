# frozen_string_literal: true

desc "Export Users in a CSV file"
task "uce:users_csv_export" => :environment do |_, args|
  user_ids = args.extras

  if (user_ids[0].include?('-'))
    range = user_ids[0].split("-")

    user_ids = Array(range[0]..range[1])
  end

  if user_ids && user_ids.length > 0
    uce_assign_country(user_ids)
    users = User.where(id: user_ids).where(id: 1..).order(:username)
  else
    uce_assign_country()
    users = User.where(id: 1..).order(:username)
  end

  file = "#{Rails.root}/public/user_data#{(0...16).map { (65 + rand(26)).chr }.join}.csv"

  headers = ["Username", "IP", "Register IP" "location", "Last Seen", "Latest Post", "Post Count", "Multiple Accounts"]

  if users.length > 0
    CSV.open(file, 'w', write_headers: true, headers: headers) do |writer|
      users.each do |user|
        ip_addresses = User.where.not(id: user.id).pluck(:ip_address, :registration_ip_address).flatten - [nil]

        multiple_accounts = ip_addresses.include?(user.ip_address)
        if user.posts.length > 0
          last_post_url = user.posts.order(created_at: :desc).first.full_url
        end

        writer << [user.username, user.ip_address, user.registration_ip_address, user.custom_fields['nationalflag_iso'], user.last_seen_at, last_post_url, user.post_count, multiple_accounts]
      end
    end

    puts "Users CSV can be found here: #{file}"
  else
    puts "No User Found!"
  end
end

def uce_assign_country(user_ids = nil)
  Geocoder.configure(
    ip_lookup: :abstract_api,
    api_key: SiteSetting.uce_abstract_api_key_for_bulk_assign
  )

  flags = YAML.safe_load(File.read(File.join(Rails.root, 'plugins', 'discourse-users-custom-csv-export', 'config', 'flags.yml')))

  if user_ids
    users = User.where(id: user_ids).where(id: 1..)
  else
    users = User.where(id: 1..)
  end

  users.each do |user|
    puts "Username: #{user.username}"
    puts "IP: #{user.ip_address}"

    if user.ip_address
      geocoder_result = Geocoder.search(user.ip_address.to_s)
      country = geocoder_result.first.data["country_code"] if geocoder_result.first

      if !country
        puts "Country name not found"
        next
      end

      puts "Country name from IP address: #{country}"
      if country && flags[country.downcase]
        puts "Username: #{user.username} National Flag is #{country}"
        user.custom_fields['nationalflag_iso'] = country.downcase
        user.save_custom_fields
      end

      sleep(0.12)
    end
  end
end