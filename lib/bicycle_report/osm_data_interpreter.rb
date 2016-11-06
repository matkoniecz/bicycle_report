# encoding: UTF-8
def get_motorized_roads
	return ['motorway', 'motorway_link', 'trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 
		'tertiary', 'tertiary_link', 'unclassified', 'residential', 'service', 'raceway', "living_street",
		'bus_guideway', 'road']
end


class And
	def initialize(conditions)
		@conditions = conditions
	end
end

class Condition
	def initialize(tag, value, relation=:equal)
		@tag = tag
		@value = value
		@relation = relation
	end

	def to_overpass
		if relation == :equal
			return "[#{tag}=#{value}]"
		end
		raise "Not handled"
	end
end


def get_bicycle_infrastructure(bb)
	return '		way[highway=cycleway](' + bb + ');
		way[highway=path][bicycle=designated](' + bb + ');
		way[highway=path][bicycle=yes](' + bb + ');
		way[highway=footway][bicycle=yes](' + bb + ');
		way[highway=pedestrian][bicycle=yes](' + bb + ');'
end

def get_nodes_on_cycle_infrastructure_query_part(bb, name)
	query = "	(\n"
	query += get_bicycle_infrastructure(bb)
	query += '
	);
	node(w)'
	if name != nil
		query += '->.' + name
	end
	query += ";\n"

	return query
end

def get_nodes_on_way(query_for_way)
	query = "[out:csv(::lat,::lon;false)];\n"
	query += query_for_way
	query += "out body;\n"

	text = get_query_result(query)
	return Overhelper.list_of_locations_from_overpass_into_array(text)
end

def get_nodes_on_cycle_infrastructure(bb)
	get_nodes_on_way(get_nodes_on_cycle_infrastructure_query_part(bb, nil))
end

def get_nodes_on_motorized_roads_query_part(bb, name)
	query = "\t(\n"
	for highway in get_motorized_roads
		query += "\t\tway[highway=" + highway + "](" + bb + ");\n"
	end
	query += '	);
	node(w)'
	if name != nil
		query += '->.' + name
	end
	query += ";\n"
	return query
end

def get_nodes_on_motorized_road(bb)
	get_nodes_on_way(get_nodes_on_motorized_roads_query_part(bb, nil))
end

def get_crossings(bb, overpass_filter)
	query = "[out:csv(::lat,::lon;false)];\n"
	query += get_nodes_on_cycle_infrastructure_query_part(bb, 'on_cycleway')
	query += get_nodes_on_motorized_roads_query_part(bb, 'on_road')
	query += '
	node.on_cycleway.on_road'+overpass_filter+';
	out body;'

	text = get_query_result(query)
	usable = Overhelper.list_of_locations_from_overpass_into_array(text)
	return usable
end

def is_there_cycleway_from_both_sides(lat, lon)
	epsilon = 0.0001
	bb = "#{lat - epsilon},#{lon + epsilon/10},#{lat + epsilon},#{lon + epsilon}"
	right = get_nodes_on_cycle_infrastructure(bb).length
	bb = "#{lat - epsilon},#{lon - epsilon},#{lat + epsilon},#{lon - epsilon/10}"
	left = get_nodes_on_cycle_infrastructure(bb).length
	if left != 0 and right != 0
		return true, "#{left} <> #{right}"
	end

	bb = "#{lat + epsilon/10}, #{lon - epsilon},#{lat + epsilon},#{lon + epsilon}"
	top = get_nodes_on_cycle_infrastructure(bb).length
	horizontal_delta = -epsilon
	bb = "#{lat - epsilon}, #{lon - epsilon},#{lat - epsilon/10},#{lon + epsilon}"
	bottom = get_nodes_on_cycle_infrastructure(bb).length
	if top != 0 and bottom != 0
		return true, "#{left} <> #{right}, #{top}^V#{bottom}"
	end

	return false, "#{left} <> #{right}, #{top}^V#{bottom}"
end

def is_there_road_from_both_sides(lat, lon)
	epsilon = 0.0001
	bb = "#{lat - epsilon},#{lon + epsilon/10},#{lat + epsilon},#{lon + epsilon}"
	right = get_nodes_on_motorized_road(bb).length
	bb = "#{lat - epsilon},#{lon - epsilon},#{lat + epsilon},#{lon - epsilon/10}"
	left = get_nodes_on_motorized_road(bb).length
	if left != 0 and right != 0
		return true, "#{left} <> #{right}"
	end

	bb = "#{lat + epsilon/10}, #{lon - epsilon},#{lat + epsilon},#{lon + epsilon}"
	top = get_nodes_on_motorized_road(bb).length
	horizontal_delta = -epsilon
	bb = "#{lat - epsilon}, #{lon - epsilon},#{lat - epsilon/10},#{lon + epsilon}"
	bottom = get_nodes_on_motorized_road(bb).length
	if top != 0 and bottom != 0
		return true, "#{left} <> #{right}, #{top}^V#{bottom}"
	end

	return false, "#{left} <> #{right}, #{top}^V#{bottom}"
end

def is_there_way_from_both_sides(lat, lon, checker)
	epsilon = 0.0001
	bb = "#{lat - epsilon},#{lon + epsilon/10},#{lat + epsilon},#{lon + epsilon}"
	right = send(checker, bb).length
	bb = "#{lat - epsilon},#{lon - epsilon},#{lat + epsilon},#{lon - epsilon/10}"
	left = send(checker, bb).length
	if left != 0 and right != 0
		return true, "#{left} <> #{right}"
	end

	bb = "#{lat + epsilon/10}, #{lon - epsilon},#{lat + epsilon},#{lon + epsilon}"
	top = send(checker, bb).length
	horizontal_delta = -epsilon
	bb = "#{lat - epsilon}, #{lon - epsilon},#{lat - epsilon/10},#{lon + epsilon}"
	bottom = send(checker, bb).length
	if top != 0 and bottom != 0
		return true, "#{left} <> #{right}, #{top}^V#{bottom}"
	end

	return false, "#{left} <> #{right}, #{top}^V#{bottom}"
end

def is_cycle_crossing(lat, lon)
	result, debug = is_there_way_from_both_sides(lat, lon, :get_nodes_on_cycle_infrastructure)
	if result
		result, debug2 = is_there_way_from_both_sides(lat, lon, :get_nodes_on_motorized_road)
		if result
			return true, debug + "/" + debug2
		end
	end
	return false, debug
end
 
def get_standard_json_query_results(filters)
	query = '[out:json][timeout:150];
(
' + filters + '
);
out body;
>;
out skel qt;'
	return get_query_result(query)
end

def get_bicycle_parkings_as_json(bb)
	filters = '  node["amenity"="bicycle_parking"](' + bb + ');
  way["amenity"="bicycle_parking"](' + bb + ');
  relation["amenity"="bicycle_parking"](' + bb + ');'
	return get_standard_json_query_results(filters)
end

def get_separated_bicycle_ways_as_json(bb, surface, additional_filters="")
	common = "[surface=#{surface}]#{additional_filters}"  + '(' + bb + ')'
	filters = '  way[highway=cycleway][foot!~"."]' + common + ';
  way[highway=cycleway][foot=no]' + common + ';
  way[cycleway=lane]' + additional_filters + '(' + bb + ');'
	['cycleway', 'path', 'footway', 'pedestrian', 'bridleway'].each {|highway|
		['designated', 'yes'].each {|bicycle|
			['surface', '"cycleway:surface"'].each { |surface_tag|
				filters += "\n  way[highway=#{highway}][bicycle=#{bicycle}][segregated=yes][#{surface_tag}=#{surface}]#{additional_filters}(#{bb});"
			}
		}
	}
	return get_standard_json_query_results(filters)
	#TODO complain about cycleway:surface + surface!=paved
end

def get_nonseparated_bicycle_ways_as_json(bb, surface, additional_filters="")
	filters = ''
	['cycleway', 'path', 'footway', 'pedestrian', 'bridleway'].each {|highway|
		['designated', 'yes'].each {|bicycle|
			['surface', '"cycleway:surface"'].each { |surface_tag|
				filters += "\n  way[highway=#{highway}][bicycle=#{bicycle}][segregated=no][#{surface_tag}=#{surface}]#{additional_filters}(#{bb});"
				if bicycle == 'yes'
					filters += "\n  way[highway=#{highway}][bicycle=#{bicycle}][segregated!~\".\"][#{surface_tag}=#{surface}]#{additional_filters}(#{bb});"
				end
			}
		}
	}
	return get_standard_json_query_results(filters)
end

def get_missing_segregation_status_bicycle_ways_as_json(bb)
	filters = '  way[highway=cycleway][foot=yes][segregated!=no][segregated!=yes]' + '(' + bb + ');'
	filters += "\n  way[highway=cycleway][foot=designated][segregated!=no][segregated!=yes]" + '(' + bb + ');'
	['path', 'footway', 'pedestrian', 'bridleway'].each {|highway|
		['designated'].each {|bicycle|
			filters += "\n  way[highway=#{highway}][bicycle=#{bicycle}][segregated!=no][segregated!=yes][cycleway!=lane](#{bb});"
		}
	}
	return get_standard_json_query_results(filters)
end

def get_bicycle_ways_as_json(bb, filter)
	query = '[out:json][timeout:250];
(
way["highway"="cycleway"]' + filter + '(' + bb + ');
way[highway=path][bicycle=designated][segregated=yes]' + filter + '(' + bb + ');
way[highway=path][bicycle=designated][segregated=no]' + filter + '(' + bb + ');
way[highway=path][bicycle=yes]' + filter + '(' + bb + ');
way[highway=footway][bicycle=yes]' + filter + '(' + bb + ');
way[highway=pedestrian][bicycle=yes]' + filter + '(' + bb + ');
);
out body;
>;
out skel qt;'
	return get_standard_json_query_results(filters)
end

def is_private(access_tag)
	if access_tag != nil
		if access_tag != "yes"
			return true
		end
	end
end