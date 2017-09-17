require 'json'
require 'faster_csv'

def data_path(fp)
  p = File.expand_path(File.join(File.dirname(__FILE__), "../data/#{fp}"))
end

def read_data(fp, json=true)
  p = data_path fp
  d = File.read(p)
  if json
    JSON.parse(d) rescue {}
  else
    d
  end
end

def write_data(fp, data)
  p = data_path fp
  `mkdir -p #{File.dirname(p)}`
  File.open(p, 'w'){|fo|fo.write(data)}
  puts "Wrote #{data.length} to #{p}"
  nil
end

def dir_from_url url
  dirname = url.split('.',2).first.split('://',2).last
end

def _sleep t
  t = t + rand(5)
  puts "Sleeping for #{t}"
  sleep rand(5)+t
end

def search url, app_id=nil,page=0, got=0
  dirname = dir_from_url url
  if File.exists?(data_path("#{dirname}/search.#{page}.json"))
    puts "skip... #{page}"
    resp = File.read(data_path("#{dirname}/search.#{page}.json"))
  else
    sort = 'total_reviews_score_sum'
    len=100
    cmd = %{
  curl '#{url}/ajax_search?_len=#{len}&page=#{page}&_sortfld=#{sort}&_sortdir=DESC&_tpl=srp&head%5B%5D=_i_1&head%5B%5D=name&head%5B%5D=_GC_review_srp&head%5B%5D=_GC_money_srp&head%5B%5D=_GC_biz_size&head%5B%5D=_urr_avg_rating&head%5B%5D=_GC_money_SRP_content&head%5B%5D=_GC_platform&head%5B%5D=total_rating_stars&head%5B%5D=reviews_count&head%5B%5D=id&head%5B%5D=_encoded_title&head%5B%5D=_avg_rating&head%5B%5D=_num_reviews&head%5B%5D=total_rating_stars&head%5B%5D=reviews_count' -H 'Cookie: _gat=1; __ats=1505622982123; _giq_lv=1505622982124; _test_cookie=1; _gqpv=1; __afct=on; _ga=GA1.2.375771251.1505622982; _gid=GA1.2.1807416851.1505622982; _gat_s=1; __ybotb=293b; __ybotu=j7o91te1kv4mzhywk4; __ybotv=1505622983688; __ybots=j7o91te2v6v4u8qjyn.1.j7o91te0072otybyms.1; D_IID=7A16E7DE-470A-34AC-A683-2676ABB48A14; D_UID=9DD666E5-F0EF-3373-8F95-C9EE47A8E24F; D_ZID=FB16E4A3-24E6-3715-B124-A45C19EC85A4; D_ZUID=DF8E6E01-6850-327A-A1A9-E5A9855A1A51; D_HID=65F3D255-721D-340E-982F-6E0505892068; D_SID=42.109.175.176:KpXElE9/Zq40Hzwuy5HpXodhhYGgETX5PwpjXv8+lxk; _ftbuptc=KLgEWsgbXEzbQI7O5ckf6ZXWwYBSDUSH; _ftbuptcs=KLgEWsgbXEzbQI7O5ckf6ZXWwYBSDUSH; OX_sd=1; OX_plg=pm; __ybotc=http%3A//ads-adseast-vpc.yldbt.com/m/; __ybotn=1; __gads=ID=68b616357784dab5:T=1505622986:S=ALNI_MaMb9MdUxyPS16ro75q-Grq3PwWUQ; _uetsid=_uetc5580319' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.79 Safari/537.36' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: http://document-management.softwareinsider.com/' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'X-Distil-Ajax: veaezadtaezyxrzbr' --compressed
    }
    resp = `#{cmd}`
    write_data("#{dirname}/search.#{page}.json", resp)
    _sleep 20
  end

    resp = JSON.parse(resp) rescue {}

    total = resp["data"]["recs"]
    l = resp["data"]["data"].length
    got = got + l
    puts "#{got} out of #{total} done."

  if got < total
    search url, app_id, page+1, got
  end

end

def cmp url
  items = gcomp url
  ids = items.map{|i|i[0]}
  dirname = dir_from_url url
  grouped = ids.each_slice(10).to_a
  puts "To Compare #{grouped.length} times!"
  puts ""
  grouped.each_with_index do |g,index|
    if File.exists?(data_path("#{dirname}/feat.#{index}.json"))
      puts "skip... #{index}"
      next
    end
    cmp_ids = g.join("-")
    cmp_url = "#{url}/compare/#{cmp_ids}/tour"
    # Handle the task to node js
    cmd = "cd  #{data_path('..')} && CMP_URL='#{cmp_url}' CMP_PAGE='#{index}' node src/compare.js"
    puts cmd
    puts `#{cmd}`
    puts "\n----------------------------------\n"
    _sleep 30
  end
end

#search 'http://document-management.softwareinsider.com'


def lcat head=nil
  categories = read_data('root.json')
  if head
    v = categories[head]
    v['child'].each do |c|
      puts ">>\t#{c['name']}"
    end
  else
    categories.each do |k, v|
      puts ">\t#{k}"
    end
  end
  nil
end

def with_gcat head='*', tail='*', opts={}
  categories = read_data('root.json')
  if head=='*'
    categories.each do |k, v|
      v['child'].each do |c|
        next if ( opts[:except] || [] ).include?(c['name'])
        link = c['link']
        yield link
      end
    end
  else
    v = categories[head]
    child = v['child'].select{|c|c['name'] == tail}.first
    link = child['link']
    puts "Getting #{head}/#{tail}.."
    yield link
  end
end

def gcomp url
  dirname = dir_from_url url
  fps = Dir.glob(data_path("#{dirname}/search.*")).sort_by{|s|s.split('.')[1].to_i}
  items = []
  fps.each do |fp|
    fn = File.basename fp
    data = read_data("#{dirname}/#{fn}")
    #items +=  data['data']['data'].map{|a|[a[-6],a[-5]]}
    x = data['data']['data']
    items +=  x.map do|a|
      #if Nokogiri::HTML.fragment(a.join).css('[data-iframe]').attr('data-iframe').value =~ /lid=([0-9]+)/
      #puts a.inspect
      #puts "----------------"
      p = data['data']['head'].index('id')
      q = data['data']['head'].index('name')
      if a[p] && a[q]
        uid = a[p]
        name = a[q]
      elsif a.join =~ /new-srp-review-([0-9]+)/m
        uid = $1
        name = a[1]
      else
        puts "ALERT!!!!!!!! btrbrt:"
        uid = a[-4]
        name = a[1]
      puts uid.inspect
      puts "----------------"
      end
      [uid,name]
    end
  end
  puts "Found #{items.length} under #{dirname}"
  items
end


def merge_all link
  dirname = dir_from_url link
  #fps = Dir.glob(data_path("#{dirname}/feat.*")).sort
  fps = Dir.glob(data_path("#{dirname}/feat.*")).sort_by{|s|s.split('.')[1].to_i}
  items = []
  tbl = []
  fps.each_with_index do |fp, index|
    i = read_data("#{dirname}/itm.#{index}.json")
    j = read_data("#{dirname}/feat.#{index}.json")
    j.each do |k,arr|
      arr.each_with_index do |a, index|
        #puts index
        #puts '---------'
        #puts itm.inspect
        #puts a.inspect
        itm = i[index]
        next if itm.nil?

        a.each do |_k,v|
          row = []
          row << k
          row << _k
          row << itm['name']
          row << ( (v)?1:0 )
          tbl << row
        end
      end
    end
  end
  puts "Found #{tbl.length} under #{dirname}"

  FasterCSV.open(data_path("#{dirname}/merged.csv"), "w", :col_sep=> "\t") do |csv|
    tbl.each do |r|
      csv << r
    end
  end
  nil
end

def do_it link
  dirname = dir_from_url link
  if File.exists?(data_path("#{dirname}/merged.csv"))
    puts "Skipping .... #{link}"
  else
    search(link); cmp(link); merge_all(link)
  end
end


=begin
with_gcat{|link| do_it(link)}

with_gcat( "Collaboration", "Document Management Software" ){|link| search(link); cmp(link); merge_all(link)}

with_gcat( "Collaboration", "Project Management Software" ){|link| do_it(link)}
with_gcat( "Collaboration", "Project Management Software" ){|link| cmp(link)}

with_gcat( "IT Management", "Database Management Systems" ){|link| do_it(link)}
with_gcat( "IT Management", "Database Management Systems" ){|link| cmp(link)}

with_gcat( "Collaboration", "Document Management Software" ) do |link|
  search link
end
=end
