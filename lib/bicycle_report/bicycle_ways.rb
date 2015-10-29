# encoding: UTF-8
require 'json'
require_relative 'requester'
require_relative 'report_generator'

class BicycleWayRaportGenerator < ReportGenerator
	def parse_josm(json_string)
		nodes = {}
		data = JSON.parse(json_string)
		for element in data["elements"]
			if element["type"] == "node"
				saved = {}
				saved[:lat] = element["lat"].to_f
				saved[:lon] = element["lon"].to_f
				nodes[element["id"]] = saved
			end
		end
		return nodes, data
	end

	def compute_full_length_and_leafletify_lines(nodes, data)
		distance_in_m = 0
		lines = ""
		for element in data["elements"]
			if element["type"] == "way"
				nodes_of_way = element["nodes"]
				prev_node = nil
				for node in nodes_of_way
					if prev_node != nil
						lat1 = (nodes[prev_node])[:lat]
						lon1 = (nodes[prev_node])[:lon]
						lat2 = (nodes[node])[:lat]
						lon2 = (nodes[node])[:lon]
						delta = Overhelper.distance_in_m(lat1, lon1, lat2, lon2)
						lines += Leafleter.get_line(lat1, lon1, lat2, lon2)
						distance_in_m += delta
					end
					prev_node = node
				end
			end
		end
		return distance_in_m, lines
	end

	def process
		#TODO - cycleway:surface
		json_string = get_separated_bicycle_ways_as_json(overpass_bb, "[surface=asphalt]")
		nodes, data = parse_josm(json_string)
		page = "bicycle_ways_ddr.html"
		distance_in_m, lines = compute_full_length_and_leafletify_lines(nodes, data)
		open(page, 'w') {|file|
			sidebar_content = "#{distance_in_m.to_i/1000} km - ścieżek"
			layer = Leafleter.get_standard_OSM_tile_Layer()
			file.puts Leafleter.get_before("title", @center_lat, @center_lon, 13, layer, @map_width_percent, sidebar_content, './main.css')
			file.puts lines
			file.puts Leafleter.get_after()
		}

		json_string = get_nonseparated_bicycle_ways_as_json(overpass_bb, "[surface=asphalt]")
		nodes, data = parse_josm(json_string)
		page = "bicycle_ways_cpr.html"
		distance_in_m, lines = compute_full_length_and_leafletify_lines(nodes, data)
		open(page, 'w') {|file|
			sidebar_content = "#{distance_in_m.to_i/1000} km - dobrych CPR"
			layer = Leafleter.get_standard_OSM_tile_Layer()
			file.puts Leafleter.get_before("title", @center_lat, @center_lon, 13, layer, @map_width_percent, sidebar_content, './main.css')
			file.puts lines
			file.puts Leafleter.get_after()
		}
	end
end
