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

log = Nokogiri::HTML(open(File.expand_path("../ImasNewsLog.html", __FILE__))).css("a")
f = File.open(File.expand_path("../ImasNews.log", __FILE__), "a")
client = Mastodon::REST::Client.new(base_url: ENV["MASTODON_URL"], bearer_token: ENV["MASTODON_ACCESS_TOKEN"])
src = "http://idolmaster.jp/"

begin
  doc = Nokogiri::HTML(open(src))
rescue
  f.puts()
  f.puts(Time.now)
  f.puts("アクセスできませんでした。\n#{src}")
  f.puts(log[-2])
  return
end

news = doc.xpath('.//div[@class="clearfix"]').css("dd").css("a")
post = Array.new

(news.length - log.length).times do |i|
  title = news[i].inner_html.split('】')
  url = news[i].attribute('href').value
  article = "【アイマスニュース】\n"
  (title.length - 1).times do |i|
    title[i] << "】"
  end
  title.each do |e|
    article << "#{e}\n"
  end
  article << url
  post << article
end

post.reverse.each do |e|
  e << "\n#imas_news"
  client.create_status(e)
  feed_list.each do |id|
    feed = "@#{client.account(id).username} \n#{e}"
    client.create_status(feed, visibility: 'direct')
  end
end

if post.length != 0
  f.puts()
  f.puts(Time.now)
  f.puts(post)
end
f.close

if (news.length - log.length) != 0
  f = File.open(File.expand_path("../ImasNewsLog.html", __FILE__),"w")
  f.puts("<!DOCTYPE HTML><html>\n<head>\n<meta charset=\"utf-8\"/>\n<title>temp file</title></head>\n<body>")
  f.puts(news)
  f.puts("</body></html>")
  f.close
end
