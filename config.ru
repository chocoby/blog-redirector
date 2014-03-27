require 'uri'

HOME_URL = 'http://chocoby.jp'
BLOG_URL = 'http://chocoby.jp/blog/'

run lambda { |env|
  request = Rack::Request.new(env)

  uri = URI.parse request.env['REQUEST_URI']

  type = redirect_type(uri)

  send("redirect_#{type}", uri)
}

def redirect_type(uri)
  host = uri.host
  path = uri.path

  # ホームページ
  if host == 'cho-co.be'
    return :home
  end

  # ブログトップ
  if path == '/'
    return :blog_home
  end

  # フィード
  if path =~ /^\/feed/
    return :blog_feed
  end

  # カレンダー
  if path =~ /^\/201[0-9]\//
    return :blog_calendar
  end

  # カテゴリ/タグ
  if path =~ /^\/category|tag\//
    return :blog_tag
  end

  # 記事
  :blog_article
end

def redirect_home(uri)
  redirect HOME_URL
end

def redirect_blog_home(uri)
  redirect BLOG_URL
end

def redirect_blog_feed(uri)
  redirect "#{BLOG_URL}feed.xml"
end

def redirect_blog_calendar(uri)
  path = uri.path.split('/')
  path.shift

  year_path = path.shift
  month_path = path.shift

  calendar_path = "#{year_path}/"

  if month_path =~ /[0-1][0-9]/
    calendar_path += "#{month_path}/"
  end

  redirect "#{BLOG_URL}#{calendar_path}"
end

def redirect_blog_tag(uri)
  path = uri.path.split('/')
  path.shift
  path.shift

  tag = path.shift

  redirect "#{BLOG_URL}tags/#{tag}/"
end

def redirect_blog_article(uri)
  path = uri.path.split('/')
  path.shift
  path.shift

  require_relative './default_mappings.rb'
  require_relative './custom_mappings.rb'

  mappings = {}
  mappings.merge! default_mappings
  mappings.merge! custom_mappings

  old_article_slug = path.shift

  begin
    redirect_info = mappings.fetch(old_article_slug)
  rescue
    return redirect_blog_home(uri)
  end

  article_date = redirect_info.shift.gsub('-', '/')
  article_slug = redirect_info.shift

  redirect "#{BLOG_URL}#{article_date}/#{article_slug}/"
end

def redirect(path)
  Rack::Response.new { |response|
    response.redirect path, 301
  }
end

def not_found
  text = 'Not Found'

  [404, {'Content-Type' => 'text/plain', 'Content-Length' => text.length.to_s}, [text]]
end
