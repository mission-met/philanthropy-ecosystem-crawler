require "metainspector"
require "nokogiri"
require "csv"


FILE_PATH = "crawler-results.csv"
HEADERS = [
  "Company Name",
  "Description",
  "URL",
  "Email",
  "Website",
  "Twitter",
]
BASE_URL = "https://platform.dkv.global/mind-map/philanthropy-industry/group/6273-Inclusive%20Development/"

base_page = MetaInspector.new(BASE_URL, encoding: "UTF-8")
rows = CSV.read(FILE_PATH) || [HEADERS]

base_page
  .links
  .internal
  .select { |url| url.match?(/\/mind-map\/firms\/\d{1,7}/) }
  .each do |url|
    next if rows.any? {|r| r.include?(url) }
    puts url
    meta_page = MetaInspector.new(url)

    page = Nokogiri(meta_page.response.body)

    company_name = meta_page.h1.first
    description = meta_page.best_description
    external_links = meta_page.links.external
    email = meta_page.links.all.select { |link| link.match?(/mailto:/) }.first&.gsub("mailto:", "")
    website = external_links.reject { |link| link.match?(/mailto:/) }.reject { |link| link.match?(/twitter/) }.first
    twitter = external_links.select { |link| link.match?(/twitter/) }.first

    rows << [
      company_name,
      description,
      url,
      email,
      website,
      twitter
    ]

    sleep rand(1.0..3)
  rescue => e
    puts "ERROR! #{e.inspect}"
  end

CSV.open(FILE_PATH) do |csv|
  rows.each do |row|
    csv << row
  end
end

