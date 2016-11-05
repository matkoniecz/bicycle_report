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

	def distance_in_m_to_text(distance_in_m)
		if distance_in_m < 4000
			return "#{distance_in_m.to_i} m"
		end
		return "#{distance_in_m.to_i/1000} km"
	end

	def generate_page_about_ways(json_string, page_title, sidebar_explanation, color)
		ways = Overhelper.convert_to_ways(json_string)
		distance_in_m, lines = compute_full_length_and_leafletify_lines(ways, color)
		open(page_title, 'w') {|file|
			sidebar_content = distance_in_m_to_text(distance_in_m)
			sidebar_content += sidebar_explanation
			layer = Leafleter.get_positron_tile_Layer()
			file.puts Leafleter.get_before("title", @center_lat, @center_lon, @starting_zoom, layer, @map_width_percent, sidebar_content, './main.css')
			file.puts lines
			file.puts Leafleter.get_after()
		}
	end

	def add_section_on_main_page_about_contraflow(filename_of_page_with_detailed_data, missing_contraflow_in_m, existing_contraflow_in_m)
		open(main_page, 'a') {|file|
			file.puts section("contraflow_title", "h2")
			file.puts "<div class=\"shadowed_box\"><h1>"
			file.puts distance_in_m_to_text(missing_contraflow_in_m)
			file.puts "</h1>"
			file.puts I18n.t("contraflow_missing_length")
			file.puts "</div>"
			file.puts section("contraflow_progress_short", "h3")
			file.puts I18n.t("contraflow_progress")
			percent_done = (100 * existing_contraflow_in_m / (existing_contraflow_in_m + missing_contraflow_in_m)).to_i
			file.puts get_progress_bar(percent_done)
			file.puts '<a href="./' + filename_of_page_with_detailed_data + '">' + I18n.t("more_including_map") + '</a>'
		}
	end

	def generate_general_contraflow_page(filename, existing_contraflow_in_m, missing_contraflow_in_m, unwanted_contraflow_in_m)
		open(filename, 'w') {|file|
			file.puts section("contraflow_title", "h2")

			file.puts "<div class=\"shadowed_box\"><h1>"
			file.puts distance_in_m_to_text(missing_contraflow_in_m)
			file.puts "</h1>"
			file.puts I18n.t("contraflow_missing_length")
			file.puts "</div>"

			file.puts "<div class=\"shadowed_box\"><h1>"
			file.puts distance_in_m_to_text(existing_contraflow_in_m)
			file.puts "</h1>"
			file.puts I18n.t("contraflow_existing_length")
			file.puts "</div>"

			file.puts "<div class=\"shadowed_box\"><h1>"
			file.puts distance_in_m_to_text(unwanted_contraflow_in_m)
			file.puts "</h1>"
			file.puts I18n.t("unwanted_contraflow_length")
			file.puts "</div>"

			file.puts I18n.t("contraflow_explanation")
			file.puts I18n.t("contraflow_progress")
			percent_done = (100 * existing_contraflow_in_m / (existing_contraflow_in_m + missing_contraflow_in_m)).to_i
			file.puts get_progress_bar(percent_done)
			file.puts '<a href="./' + "bicycle_ways_missing_contraflow.html" + '">' + I18n.t("more_including_map") + '</a>'
			file.puts '<a href="./' + "bicycle_ways_existing_contraflow.html" + '">' + I18n.t("more_including_map") + '</a>'
			file.puts '<a href="./' + "bicycle_ways_unwanted_contraflow.html" + '">' + I18n.t("more_including_map") + '</a>'
			file.puts '<a href="./' + "bicycle_ways_dual_carriageway.html" + '">' + I18n.t("more_including_map") + '</a>'
		}
	end

	def contraflow(contraflow_exceptions_by_names, contraflow_unwanted_by_names)
		json_string = get_missing_contraflow_as_json(overpass_bb, contraflow_exceptions_by_names)
		ways = Overhelper.convert_to_ways(json_string)
		missing_contraflow_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')
		sidebar_explanation = " - #{I18n.t('missing_contraflow_title')}<br><br>#{I18n.t('missing_contraflow').gsub("\n", '<br>')}"
		page_title = "bicycle_ways_missing_contraflow.html"
		generate_page_about_ways(json_string, page_title, sidebar_explanation, 'red')

		json_string = existing_contraflow_as_json(overpass_bb)
		ways = Overhelper.convert_to_ways(json_string)
		existing_contraflow_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')
		sidebar_explanation = " - #{I18n.t('existing_contraflow_title')}<br><br>#{I18n.t('existing_contraflow').gsub("\n", '<br>')}"
		page_title = "bicycle_ways_existing_contraflow.html"
		generate_page_about_ways(json_string, page_title, sidebar_explanation, 'green')

		json_string = unwanted_contraflow_as_json(overpass_bb, contraflow_unwanted_by_names)
		ways = Overhelper.convert_to_ways(json_string)
		unwanted_contraflow_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')
		sidebar_explanation = " - #{I18n.t('unwanted_contraflow_title')}<br><br>#{I18n.t('unwanted_contraflow').gsub("\n", '<br>')}"
		page_title = "bicycle_ways_unwanted_contraflow.html"
		generate_page_about_ways(json_string, page_title, sidebar_explanation, 'purple')

		json_string = dual_carriageway_as_json(overpass_bb, contraflow_unwanted_by_names)
		sidebar_explanation = " - #{I18n.t('dual_carriageway_title')}<br><br>#{I18n.t('dual_carriageway').gsub("\n", '<br>')}"
		page_title = "bicycle_ways_dual_carriageway.html"
		generate_page_about_ways(json_string, page_title, sidebar_explanation, 'purple')

		filename_of_page_with_detailed_data = 'contraflow.html'
		generate_general_contraflow_page(filename_of_page_with_detailed_data, existing_contraflow_in_m, missing_contraflow_in_m, unwanted_contraflow_in_m)
		add_section_on_main_page_about_contraflow(filename_of_page_with_detailed_data, missing_contraflow_in_m, existing_contraflow_in_m)
	end

	def process(contraflow_exceptions_by_names, contraflow_unwanted_by_names)
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
		sidebar_explanation = " - brak segregated=yes/no"
		page_title = "bicycle_ways_missing_segregated_info.html"
		generate_page_about_ways(json_string, page_title, sidebar_explanation, 'purple')

		contraflow(contraflow_exceptions_by_names, contraflow_unwanted_by_names)
	end
end
