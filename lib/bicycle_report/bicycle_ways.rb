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

	def title_to_html_filename(title)
		# TODO - ensure unique titles

		# title is assumed to be safe input, not controlled by an attacker

		# escape characters that would break saving file, as this characters may not be used in filename
		# there is no better solution according to http://stackoverflow.com/questions/2270635/invalid-chars-filter-for-file-folder-name-ruby
		title = title.gsub(/[\x00\/\\:\*\?\"<>\|]/, '_')

		# escape characters that would break html (especially <a href="...)
		# http://stackoverflow.com/questions/7381974/which-characters-need-to-be-escaped-on-html
		title = title.gsub(/<>&/, '_')
		return title + ".html"
	end

	def generate_page_about_ways(json_string, translation_code, color)
		title = I18n.t(translation_code+'_title')
		page_filename = title_to_html_filename(title)
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
		text += '<a href="./' + subpage_filename + '">' + '<br>' + I18n.t("more_including_map") + '</a>'
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
			file.puts get_box_with_way_summary('contraflow_missing_length', @missing_contraflow_in_m, title_to_html_filename(I18n.t('contraflow_missing' + '_title')))
			file.puts get_box_with_way_summary('contraflow_existing_length', @existing_contraflow_in_m, title_to_html_filename(I18n.t('contraflow_existing' + '_title')))
			file.puts get_box_with_way_summary('contraflow_unwanted_length', @unwanted_contraflow_in_m, title_to_html_filename(I18n.t('contraflow_unwanted' + '_title')))

			file.puts I18n.t("contraflow_explanation")
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
		filename_of_page_with_detailed_data = title_to_html_filename(I18n.t('contraflow_title' + '_title'))
		generate_general_contraflow_page(filename_of_page_with_detailed_data)
		add_section_on_main_page_about_contraflow(filename_of_page_with_detailed_data)
	end

	def contraflow()
		contraflow_generate_detailed_pages()
		contraflow_generate_general_pages()
	end

	def get_box_with_way_summary_simplified(translation_code, length_in_m)
		get_box_with_way_summary(translation_code+'_length', length_in_m, title_to_html_filename(I18n.t(translation_code + '_title')))
	end

	def other_cycling_infrastructure() #TODO - better name needed
		cycleway_json_string = get_separated_bicycle_ways_as_json(overpass_bb, "asphalt")
		sidebar_explanation = " - #{I18n.t('cycling_infrastructure_cycleway')}<br><br>#{I18n.t('cycling_infrastructure_cycleway')}"
		generate_page_about_ways(cycleway_json_string, 'cycling_infrastructure_cycleway', 'green')

		cycling_infrastructure_shared_use_optional_json_string = get_nonseparated_bicycle_ways_as_json(overpass_bb, "asphalt", "[bicycle=yes]")
		generate_page_about_ways(cycling_infrastructure_shared_use_optional_json_string, 'cycling_infrastructure_shared_use_optional', 'green')

		infrastructure_shared_use_obligatory_json_string = get_nonseparated_bicycle_ways_as_json(overpass_bb, "asphalt", "[bicycle=designated]")
		generate_page_about_ways(infrastructure_shared_use_obligatory_json_string, 'cycling_infrastructure_shared_use_obligatory', 'orange')

		bad_obligatory_bicycle_ways_json_string = get_bad_obligatory_bicycle_ways_as_json(overpass_bb)
		generate_page_about_ways(bad_obligatory_bicycle_ways_json_string, 'cycling_infrastructure_bad_and_obligatory', 'red')

		json_string = get_missing_segregation_status_bicycle_ways_as_json(overpass_bb)
		generate_page_about_ways(json_string, 'cycling_infrastructure_debug_missing_segregated_key', 'red')

		filename_of_page_with_detailed_data = title_to_html_filename(I18n.t('cycling_infrastructure_title'))

		open(main_page, 'a') {|file|
			file.puts section("cycling_infrastructure_cycleway_title", "h2")
			ways = Overhelper.convert_to_ways(cycleway_json_string)
			length_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')
			file.puts get_box_with_way_summary('cycling_infrastructure_cycleway_length', length_in_m, filename_of_page_with_detailed_data)
		}

		start_writing_page(filename_of_page_with_detailed_data, 'cycling_infrastructure_title')
		open(filename_of_page_with_detailed_data, 'a') {|file|
			file.puts section("cycling_infrastructure_cycleway_title", "h2")

			ways = Overhelper.convert_to_ways(cycleway_json_string)
			length_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')
			file.puts get_box_with_way_summary_simplified('cycling_infrastructure_cycleway', length_in_m)

			ways = Overhelper.convert_to_ways(cycling_infrastructure_shared_use_optional_json_string)
			length_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')
			file.puts get_box_with_way_summary_simplified('cycling_infrastructure_shared_use_optional', length_in_m)

			ways = Overhelper.convert_to_ways(infrastructure_shared_use_obligatory_json_string)
			length_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')
			file.puts get_box_with_way_summary_simplified('cycling_infrastructure_shared_use_obligatory', length_in_m)\

			ways = Overhelper.convert_to_ways(bad_obligatory_bicycle_ways_json_string)
			length_in_m, _ = compute_full_length_and_leafletify_lines(ways, 'color')
			file.puts get_box_with_way_summary_simplified('cycling_infrastructure_bad_and_obligatory', length_in_m)

			file.puts I18n.t("cycling_infrastructure_explanation")
		}
		finish_writing_page(filename_of_page_with_detailed_data)

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
