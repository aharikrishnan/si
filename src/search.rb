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

def search url, app_id=nil,page=0, got=0
  dirname = dir_from_url url
  if File.exists?(data_path("#{dirname}/search.#{page}.json"))
    puts "skip... #{page}"
    resp = File.read(data_path("#{dirname}/search.#{page}.json"))
  else
    sort = 'total_reviews_score_sum'
    len=100
    cmd = %{
  curl '#{url}/ajax_search?_len=#{len}&page=#{page}&_sortfld=#{sort}&_sortdir=DESC&_tpl=srp&head%5B%5D=_i_1&head%5B%5D=name&head%5B%5D=_GC_review_srp&head%5B%5D=_GC_money_srp&head%5B%5D=_GC_biz_size_srp&head%5B%5D=_GC_money_SRP_content&head%5B%5D=_GC_platform&head%5B%5D=applications&head%5B%5D=total_reviews_score_sum&head%5B%5D=avg_review_rating&head%5B%5D=review_count&head%5B%5D=id&head%5B%5D=_encoded_title&head%5B%5D=total_reviews_score_sum&head%5B%5D=avg_review_rating&head%5B%5D=review_count' -H 'Cookie: D_SID=157.50.12.165:GqDhSeVksgCWAipNTdvPPze2h0O8Hhwx2BAR35evzVs; _giq_lv=1505596483124; __gads=ID=ba9cfc5d83a433fe:T=1505596486:S=ALNI_Mau7CFxG3mubC9JyBZlBKr2DEBPjg; ftb_ip_information=city%3DChennai%26countryCode%3DIN%26countryName%3DIndia%26region%3DTamil%2BN%25C4%2581du%26regionCode%3D25%26regionName%3DTamil%2BN%25C4%2581du%26latitude%3D13.0833%26longitude%3D80.2833%26postCode%3D600003; _gat=1; __ats=1505597077863; _test_cookie=1; _gqpv=2; __afct=on; _ga=GA1.2.1754090284.1505596483; _gid=GA1.2.1603555450.1505596483; _gat_s=1; __ybotb=293b; __ybotu=j7nt9u6tga79sc2u9z; __ybotv=1505597079192; __ybots=j7ntmlcpkyecffsqq7.0.j7ntmlcn24kjrpif5n.1; D_IID=B49B2625-7015-313D-9DE5-D65D86994527; D_UID=1898E773-B523-33F2-8597-F379023752C6; D_ZID=B5C38AA3-7A62-3DE9-8D75-5B042FD66A14; D_ZUID=6C2EBEA2-8372-3F90-BD3F-8440E3905ADE; D_HID=351F5E21-A3FD-3C70-8066-D3A7726E89FC; _ftbuptc=zJw8gQzrBAOtimxCnJ3Jx8MVq7Lr8yRy; _ftbuptcs=zJw8gQzrBAOtimxCnJ3Jx8MVq7Lr8yRy; OX_sd=2; OX_plg=pm; _uetsid=_uet8ebe2b66; __ybotc=http%3A//ads-adseast-vpc.yldbt.com/m/; __ybotn=1' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Referer: http://cmms.softwareinsider.com/' -H 'X-Requested-With: XMLHttpRequest' -H 'Connection: keep-alive' -H 'X-Distil-Ajax: wbyqxeqbwzrwfqrqddrwtyevwdsdtrwxeftswc' --compressed
    }
    resp = `#{cmd}`
    write_data("#{dirname}/search.#{page}.json", resp)
    sleep rand(5)+1
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
    cmp_url = "#{url}/compare/#{cmp_ids}/bar"
    # Handle the task to node js
    cmd = "cd  #{data_path('..')} && CMP_URL='#{cmp_url}' CMP_PAGE='#{index}' node src/compare.js"
    #puts cmd
    puts `#{cmd}`
    puts "\n----------------------------------\n"
    sleep rand(5)+1
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
