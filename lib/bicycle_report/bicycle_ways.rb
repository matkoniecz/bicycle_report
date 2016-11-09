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
		distance_in_km = distance_in_m/1000.0
		if distance_in_km < 4
			return "#{'%.1f' % distance_in_km} km"
		end
		return "#{'%.0f' % distance_in_km} km"
	end

	def generate_page_about_ways(json_string, translation_code, color)
		title = I18n.t(translation_code+'_title')
		page_filename = title+'.html' #TODO - ensure unique titles
		ways = Overhelper.convert_to_ways(json_string)
		distance_in_m, lines = compute_full_length_and_leafletify_lines(ways, color)
		open(page_filename, 'w') {|file|
			sidebar_content = distance_in_m_to_text(distance_in_m)
			sidebar_content += sidebar_explanation(translation_code)
			layer = Leafleter.get_positron_tile_Layer()
			file.puts Leafleter.get_before(title, @center_lat, @center_lon, @starting_zoom, layer, @map_width_percent, sidebar_content, './main.css')
			file.puts lines
			file.puts Leafleter.get_after()
		}
	end

	def get_bar_about_contraflow_progress()
		percent_done = (100 * @existing_contraflow_in_m / (@existing_contraflow_in_m + @missing_contraflow_in_m)).to_i

		text = section("contraflow_progress_short", "h3")
		text += I18n.t("contraflow_progress")
		text += get_progress_bar(percent_done)

		return text
	end

	def get_box_with_way_summary(description_translation_code, length_in_m, subpage_filename)
		text = ""
		text += "<div class=\"shadowed_box\"><h1>"
		text += distance_in_m_to_text(length_in_m)
		text += "</h1>"
		text += I18n.t(description_translation_code)
		text += '<a href="./' + subpage_filename + '">' + I18n.t("more_including_map") + '</a>'
		text += "</div>"
	end

	def add_section_on_main_page_about_contraflow(filename_of_page_with_detailed_data)
		open(main_page, 'a') {|file|
			file.puts section("contraflow_title", "h2")
			file.puts get_box_with_way_summary('contraflow_existing_length', @existing_contraflow_in_m, filename_of_page_with_detailed_data)
			file.puts get_bar_about_contraflow_progress()
		}
	end

	def generate_general_contraflow_page(filename)
		start_writing_page(filename, 'contraflow_title')
		open(filename, 'a') {|file|
			file.puts section("contraflow_title", "h2")

			file.puts get_bar_about_contraflow_progress()
			file.puts get_box_with_way_summary('contraflow_missing_length', @missing_contraflow_in_m, I18n.t('contraflow_missing' + '_title') + '.html')
			file.puts get_box_with_way_summary('contraflow_existing_length', @existing_contraflow_in_m, I18n.t('contraflow_existing' + '_title') + '.html')
			file.puts get_box_with_way_summary('contraflow_unwanted_length', @unwanted_contraflow_in_m, I18n.t('contraflow_unwanted' + '_title') + '.html')

			file.puts I18n.t("contraflow_explanation")

			file.puts '<a href="./' + "bicycle_ways_dual_carriageway.html" + '">' + I18n.t("more_including_map") + '</a>'
		}
		finish_writing_page(filename)
	end

	def sidebar_explanation(translation_code)
		" - #{I18n.t("#{translation_code}_title")}<br><br>#{I18n.t(translation_code)}"
	end

	def contraflow_generate_detailed_pages()
		json_string = get_missing_contraflow_as_json(overpass_bb, @names_of_streets_certain_to_not_be_oneway + @names_of_streets_where_contraflow_is_unwanted)
		translation_code = 'contraflow_missing'
		generate_page_about_ways(json_string, translation_code, 'red')

		json_string = existing_contraflow_as_json(overpass_bb)
		translation_code = 'contraflow_existing'
		generate_page_about_ways(json_string, translation_code, 'green')

		json_string = unwanted_contraflow_as_json(overpass_bb, @names_of_streets_where_contraflow_is_unwanted)
		translation_code = 'contraflow_unwanted'
		generate_page_about_ways(json_string, translation_code, 'purple')

		json_string = dual_carriageway_as_json(overpass_bb)
		translation_code = 'contraflow_debug_dual_carriageway'
		generate_page_about_ways(json_string, translation_code, 'purple')
	end

	def contraflow_generate_general_pages()
		filename_of_page_with_detailed_data = 'contraflow.html'
		generate_general_contraflow_page(filename_of_page_with_detailed_data)
		add_section_on_main_page_about_contraflow(filename_of_page_with_detailed_data)
	end

	def contraflow()
		contraflow_generate_detailed_pages()
		contraflow_generate_general_pages()
	end

	def other_cycling_infrastructure() #TODO - better name needed
		json_string = get_separated_bicycle_ways_as_json(overpass_bb, "asphalt")
		sidebar_explanation = " - #{I18n.t('cycling_infrastructure_cycleway')}<br><br>#{I18n.t('cycling_infrastructure_cycleway')}"
		sidebar_explanation = " - asfaltowych dróg dla rowerów i ulic z pasem dla rowerów w obu kierunkach (kontrapasy nie są wliczane)"
		generate_page_about_ways(json_string, 'cycling_infrastructure_cycleway', 'green')

		json_string = get_nonseparated_bicycle_ways_as_json(overpass_bb, "asphalt", "[bicycle=designated]")
		sidebar_explanation = " - asfaltowych chodników z dopuszczonym ruchem rowerowym tam gdzie rowerzysta jest zmuszony z ich skorzystać jeśli są w jego \"kierunku jazdy\")"
		generate_page_about_ways(json_string, 'cycling_infrastructure_shared_use_obligatory', 'green')

		json_string = get_nonseparated_bicycle_ways_as_json(overpass_bb, "asphalt", "[bicycle=yes]")
		sidebar_explanation = " - asfaltowych chodników z dopuszczonym ruchem rowerowym tam gdzie rowerzysta może ale nie musi z ich korzystać"
		generate_page_about_ways(json_string, 'cycling_infrastructure_shared_use_optional', 'green')

		json_string = get_missing_segregation_status_bicycle_ways_as_json(overpass_bb)
		sidebar_explanation = " - brak segregated=yes/no"
		generate_page_about_ways(json_string, 'cycling_infrastructure_debug_missing_segregated_key', 'green')
	end

	def process(names_of_streets_certain_to_not_be_oneway, names_of_streets_where_contraflow_is_unwanted)
		@names_of_streets_certain_to_not_be_oneway = names_of_streets_certain_to_not_be_oneway
		@names_of_streets_where_contraflow_is_unwanted = names_of_streets_where_contraflow_is_unwanted

		json_string = get_missing_contraflow_as_json(overpass_bb, @names_of_streets_certain_to_not_be_oneway)
		ways = Overhelper.convert_to_ways(json_string)
		@missing_contraflow_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')

		json_string = existing_contraflow_as_json(overpass_bb)
		ways = Overhelper.convert_to_ways(json_string)
		@existing_contraflow_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')

		json_string = unwanted_contraflow_as_json(overpass_bb, @names_of_streets_where_contraflow_is_unwanted)
		ways = Overhelper.convert_to_ways(json_string)
		@unwanted_contraflow_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')

		other_cycling_infrastructure()
		contraflow()
	end
end
