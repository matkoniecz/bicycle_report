# encoding: UTF-8
require 'json'
require_relative 'requester'
require_relative 'report_generator'

class BicycleParkingRaportGenerator < ReportGenerator
	def is_relevant_bicycle_parking(element)
		tags = element["tags"]
		if tags == nil
			return false
		end
		if tags["amenity"] != "bicycle_parking"
			return false
		end
		if is_private(tags["access"])
			return false
		end
		return true
	end

	def generate_statistics_about_bicycle_parkings
		elements = 0
		elements_missing_capacity = 0

		total_capacity = 0

		data = JSON.parse(get_bicycle_parkings_as_json(overpass_bb))
		for element in data["elements"]
			if !is_relevant_bicycle_parking(element)
				next
			end
			elements += 1
			capacity = element["tags"]["capacity"]
			if capacity == nil
				elements_missing_capacity += 1
			else
				total_capacity += capacity.to_i
			end
		end

		average_capacity = total_capacity/(elements-elements_missing_capacity)
		capacity_storage = Hash.new(0)

		for element in data["elements"]
			if is_relevant_bicycle_parking(element)
				capacity = element["tags"]["capacity"]
				if capacity == nil
					capacity = average_capacity
				else
					capacity = capacity.to_i
				end
				capacity_storage[element["tags"]["bicycle_parking"]] += capacity
			end
		end

		puts elements
		puts elements_missing_capacity
		puts capacity_storage

		good = ["stands"]
		bad = ["wall_loops"]
		good_count = 0
		bad_count = 0
		unrecognised_count = 0
		for type in capacity_storage
			if good.include?(type[0])
				good_count += type[1].to_i
			elsif bad.include?(type[0])
				bad_count += type[1].to_i
			else
				unrecognised_count += type[1].to_i
			end
		end

		tagged = good_count + bad_count + unrecognised_count
		type_tagged_percent = tagged*100/(tagged + capacity_storage[nil])
		good_type_percent = good_count*100/(good_count + bad_count)
		good_count_estimated = (good_count + capacity_storage[nil]*good_type_percent/100).to_i
		bad_count_estimated = (bad_count + capacity_storage[nil]*(100-good_type_percent)/100).to_i

		open(main_page, 'a') {|file|
			file.puts section("bicycle_parking_title", "h2")
			file.puts section("bicycle_parking_quality", "h3")
			file.puts "<div class=\"shadowed_box\"><h1>"
			file.puts good_count_estimated
			file.puts "</h1>"
			file.puts I18n.t("bicycle_parking_real_parking_count_description")
			file.puts "</div>"
			file.puts section("wall_loop_title", "h4")
			file.puts "<img src=https://www.camcycle.org.uk/resources/cycleparking/guide/wheelbenders.jpg>"
			file.puts I18n.t("about_wall_loop")
			file.puts get_progress_bar((good_count_estimated*100/tagged).to_i, "#{I18n.t("wall_loops_remaining")} #{bad_count_estimated}")
		}

		open(osm_state_page, 'a') {|file|
			file.puts section("bicycle_parking_capacity_title", "h2")
			file.puts I18n.t("bicycle_parking_capacity_tagging_progress")
			file.puts get_progress_bar(elements*100/(elements+elements_missing_capacity))
			file.puts section("bicycle_parking_type_title", "h2")
			file.puts I18n.t("bicycle_parking_tagged_type")
			file.puts get_progress_bar(type_tagged_percent)
			file.puts I18n.t("bicycle_parking_recognised_type")
			file.puts get_progress_bar((good_count + bad_count)*100/tagged)
		}
	end
end