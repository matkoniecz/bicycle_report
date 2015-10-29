$cache = Persistent::Cache.new("cache", 360000) # 100 hour freshness

def fetch(url)
	begin
		sleep 1
		return String.new(RestClient.get(url, :user_agent => ARGV[0]).to_str)
	rescue
		sleep 10
		retry
	end
end

def get_query_result(query)
	url = URI.escape("http://overpass-api.de/api/interpreter?data=#{query.gsub("\n", "")}")
   hash = Digest::SHA1.hexdigest url


	if $cache[hash] == nil
		puts query
		puts "fetching #{url}"
		from_overpass = fetch(url)
		$cache[hash] = from_overpass
	end
	return $cache[hash]
end
 

