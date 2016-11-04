# encoding: UTF-8
require 'json'
require 'overhelper'
require_relative 'requester'
require_relative 'report_generator'

class BicycleWayRaportGenerator < ReportGenerator
	def compute_full_length_and_leafletify_lines(ways, color='green')
		distance_in_m = 0
		lines = ""
		for way in ways
			lat1 = way[:lat1]
			lon1 = way[:lon1]
			lat2 = way[:lat2]
			lon2 = way[:lon2]
			delta = Overhelper.distance_in_m(lat1, lon1, lat2, lon2)
			lines += Leafleter.get_line(lat1, lon1, lat2, lon2, color, 1, 1)
			distance_in_m += delta
		end
		return distance_in_m, lines
	end

	def generate_page_about_ways(json_string, page_title, sidebar_explanation, color)
		ways = Overhelper.convert_to_ways(json_string)
		distance_in_m, lines = compute_full_length_and_leafletify_lines(ways, color)
		open(page_title, 'w') {|file|
			sidebar_content = "#{distance_in_m.to_i/1000} km"
			sidebar_content += sidebar_explanation
			layer = Leafleter.get_positron_tile_Layer()
			file.puts Leafleter.get_before("title", @center_lat, @center_lon, 13, layer, @map_width_percent, sidebar_content, './main.css')
			file.puts lines
			file.puts Leafleter.get_after()
		}
	end

	def process
		#TODO - cycleway:surface
		json_string = get_separated_bicycle_ways_as_json(overpass_bb, "asphalt")
		sidebar_explanation = " - asfaltowych dróg dla rowerów i ulic z pasem dla rowerów w obu kierunkach (kontrapasy nie są wliczane)"
		page_title = "bicycle_ways_ddr.html"
		generate_page_about_ways(json_string, page_title, sidebar_explanation, 'green')


		json_string = get_nonseparated_bicycle_ways_as_json(overpass_bb, "asphalt")
		sidebar_explanation = " - asfaltowych chodników z dopuszczonym ruchem rowerowym (zarówno tam gdzie rowerzysta jest zmuszony z ich skorzystać jeśli są w jego \"kierunku jazdy\" jak i te gdzie korzystanie jest dobrowolne)"
		page_title = "bicycle_ways_cpr.html"
		generate_page_about_ways(json_string, page_title, sidebar_explanation, 'green')

		json_string = get_missing_segregation_status_bicycle_ways_as_json(overpass_bb)
		sidebar_explanation = " - asfaltowych chodników z dopuszczonym ruchem rowerowym (zarówno tam gdzie rowerzysta jest zmuszony z ich skorzystać jeśli są w jego \"kierunku jazdy\" jak i te gdzie korzystanie jest dobrowolne)"
		page_title = "bicycle_ways_missing_segregated_info.html"
		generate_page_about_ways(json_string, page_title, sidebar_explanation, 'purple')
	end
end
