#! ruby -Ku
require 'nokogiri'
require 'open-uri'
require 'mastodon'
require 'date'
require 'dotenv'

Dir.chdir(File.expand_path("../", __FILE__))
Dotenv.load

begin
  f = File.open(File.expand_path(ENV["FEED_LIST"], __FILE__), "r")
  feed_list = f.readlines.map do |l|
    l.to_i
  end
rescue
  feed_list = []
end

log = Nokogiri::HTML(open(File.expand_path("../ImasNewsLog.html", __FILE__))).xpath('.//div[@class="news-contents has-result"]/ul/li')
f = File.open(File.expand_path("../ImasNews.log", __FILE__), "a")
client = Mastodon::REST::Client.new(base_url: ENV["MASTODON_URL"], bearer_token: ENV["MASTODON_ACCESS_TOKEN"])
src = "https://idolmaster-official.jp/news/"

begin
  doc = Nokogiri::HTML(URI.open(src))
rescue
  f.puts()
  f.puts(Time.now)
  f.puts("アクセスできませんでした。\n#{src}")
  f.puts(log[-2])
  return
end

news = doc.xpath('.//div[@class="news-contents has-result"]/ul/li')

news.reverse.each do |n|
  title = n.xpath('.//div[@class="text-area"]/p[@class="text"]')&.inner_text
  url = n.xpath('.//a')&.attribute("href").value
  next if log.map{|x| x.xpath('.//a')&.attribute("href").value}.include?(url)
  post = "【アイマスニュース】\n#{title}\n#{url}"
  client.create_status("#{post}\n#imas_news")
  feed_list.each do |id|
    feed = "@#{client.account(id).acct} \n#{post}"
    client.create_status(feed, visibility: 'direct')
  end
  f.puts()
  f.puts(Time.now)
  f.puts(post)
end
f.close

log_html = File.open(File.expand_path("../ImasNewsLog.html", __FILE__),"w")
log_html.puts(doc)
