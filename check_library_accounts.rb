require 'mechanize'
require 'logger'
require 'csv'

## This script checks multiple Denver Library accounts

def login(name,password)
	mechanize = Mechanize.new
	agent = mechanize.get('https://catalog.denverlibrary.org/logon.aspx')
	form = agent.form_with(:action=> '/Mobile/MyAccount/Logon')
   
	user_field = form.field_with(:id=> 'barcodeOrUsername').value = name
	password_field = form.field_with(:name=> 'password').value = password
	accountpage = form.submit
end

def set_accounts(source)
  ## loads library accounts from an external CSV file in the format:
  ## account number, password
  account_hash = Hash.new
    CSV.foreach(source) do |row|
        name = row[0]
        pass = row[1]
        account_hash[name] = pass
    end
  return account_hash
end

accounts = set_accounts("./accounts.csv")

accounts.each_pair do |name,pass|
  puts "Books out for #{name}"
  accountpage = login(name,pass)

  items_out_page = accountpage.link_with(:href =>"/Mobile/MyAccount/ItemsOut").click

  File.open("sample.txt", "w"){ |somefile| somefile.puts items_out_page.body}

  file = File.open("sample.txt", "r")
  contents = file.read

  page = Nokogiri::HTML(open("sample.txt"))

  #check for no items out

  no_items = page.css('#main').text
  if (no_items =~ /No items are out/)
    puts "Nothing checked out"
    puts
  else
    page.css('td.list-table-item').each do |ppo|
      #puts ppo
      re = ppo.to_s
      #puts re
      r1 = /<a href=\"\/Mobile\/ItemsOut\/Details\/.*\">(.*)<\/a>.*Due:&nbsp;(.*)&nbsp;&nbsp;<img/.match(re)
      #puts r1.class
      puts "#{$2}\t\t#{$1}" unless r1 == nil
      #puts $2
      #puts $2
      #puts r1
    end
    puts
  end


end


=begin
puts "Searching for items out"
x = page.search('.list-table-item')
puts "==> #{x}\n"

post_links = items_out_page.links.find_all { |l| l.attributes.parent.name == 'table' }

post_links.each do | pp |
	puts "**** #{pp}"
end

items_out_page.links_with(:href =>"/ItemsOut").each do |link|
  puts link.href
end
=end
