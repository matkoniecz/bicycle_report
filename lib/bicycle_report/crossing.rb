# encoding: UTF-8
require_relative 'requester'
require_relative 'report_generator'
require_relative 'osm_data_interpreter'

class CrossingReportGenerator < ReportGenerator
	def wrap_sidebar(sidebar_content)
		return '<div class="box">' + sidebar_content + '</div>'
	end

	def get_sidebar_for_main_crossing_page()
		sidebar_content = ""
		sidebar_content += section("uncycleable_crossing_title", "h2")
		sidebar_content += get_progress_bar(@ok_percent, I18n.t("uncycleable_crossing_progress_short"))
		sidebar_content += section("uncycleable_crossing_general_description", "p")
		sidebar_content += section("uncycleable_crossing_general_pl_law_change", "p")
		sidebar_content += section("uncycleable_crossing_alternatives", "p")
		return wrap_sidebar(sidebar_content)
	end

	def generate_general_html_file_about_crossings(page)
		sidebar_content = get_sidebar_for_main_crossing_page()
		title = I18n.t("uncycleable_crossing_title")
		layer = Leafleter.get_positron_tile_Layer()

		open(page, 'w') {|file|
			file.puts Leafleter.get_before(title, @center_lat, @center_lon, 13, layer, @map_width_percent, sidebar_content, './main.css')
			style = {:color => "'red'", :opacity => 1}
			@bad_crossings.each{|crossing|
				file.puts Leafleter.get_circle_marker("nielegalny przejazd", crossing[:lat], crossing[:lon], 3, style)
			}
			file.puts Leafleter.get_after()
		}
	end

	def generate_debug_html_file_about_crossings(page)
		title = I18n.t("uncycleable_crossing_title")
		layer = Leafleter.get_standard_OSM_tile_Layer()

		open(page, 'w') {|file|
			sidebar = get_progress_bar(@mapped_percent) + I18n.t("crossing_debug_sidebar")
			file.puts Leafleter.get_before(title, @center_lat, @center_lon, 13, layer, @map_width_percent, sidebar, './main.css')
			style = {:color => "'black'", :opacity => 1}
			@unknown_crossings.each{|crossing|
				file.puts Leafleter.get_circle_marker("", crossing[:lat], crossing[:lon], 3, style)
			}

			style = {:color => "'red'", :opacity => 1}
			@likely_missing_crossings.each{|crossing|
				status, debug = is_cycle_crossing(crossing[:lat], crossing[:lon])
				file.puts Leafleter.get_circle_marker(debug, crossing[:lat], crossing[:lon], 3, style)
				puts debug
				puts
			}

			style = {:color => "'blue'", :opacity => 1}
			@bad_but_no_crossings.each{|weird_block|
				file.puts Leafleter.get_circle_marker("", weird_block[:lat], weird_block[:lon], 3, style)
				puts
			}
			file.puts Leafleter.get_after()
		}
	end

	def fetch_crossing_data()
		@bad_crossings = get_crossings(overpass_bb, '[bicycle = no][highway = crossing]')
		@good_crossings = get_crossings(overpass_bb, '[bicycle = yes][highway = crossing]')
		@unknown_crossings = get_crossings(overpass_bb, '[bicycle != yes][bicycle != no][highway = crossing]')
		@bad_but_no_crossings = get_crossings(overpass_bb, '[bicycle = no][highway != crossing]')
		maybe_missing_crossings = get_crossings(overpass_bb, '[highway != crossing]')
		@likely_missing_crossings = []

		return

		#rethink this
		limit = 5
		maybe_missing_crossings[0..limit].each{|crossing|
			status, debug = is_cycle_crossing(crossing[:lat], crossing[:lon])
			if status
				@likely_missing_crossings << crossing
			end
		}
	end

	def output_numbers()
		puts "bad crossing: #{@bad_crossings.length}"
		puts "good crossing: #{@good_crossings.length}"
		puts "unknown crossing: #{@unknown_crossings.length}"
		puts "unexpected bad crossing: #{@bad_but_no_crossings.length}"
		puts "missing highway=crossing: #{@likely_missing_crossings.length}"
	end

	def calculate_statistics()
		bad = @bad_crossings.length
		good = @good_crossings.length
		unknown = @unknown_crossings.length
		@ok_percent = good * 100 / (good + bad)
		@mapped_percent = (good + bad) *100 / (good + bad + unknown)		
	end

	def add_section_on_main_page(filename_of_page_with_detailed_data)
		open(main_page, 'a') {|file|
			file.puts section("uncycleable_crossing_title", "h2")
			file.puts "<div class=\"shadowed_box\"><h1>"
			file.puts @bad_crossings.length
			file.puts "</h1>"
			file.puts I18n.t("uncycleable_crossing_count")
			file.puts "</div>"
			file.puts section("uncycleable_crossing_progress_short", "h3")
			file.puts I18n.t("uncycleable_crossing_removing_progress")
			file.puts get_progress_bar(@ok_percent)
			file.puts '<a href="./' + filename_of_page_with_detailed_data + '">' + I18n.t("more_including_map") + '</a>'
		}
	end

	def generate_html_files_about_crossings()
		fetch_crossing_data()
		output_numbers()
		calculate_statistics()

		debug_filename = 'crossing_debug.html'
		filename_of_page_with_detailed_data = 'crossings.html'
		generate_general_html_file_about_crossings(filename_of_page_with_detailed_data)
		generate_debug_html_file_about_crossings(debug_filename)

		layer = Leafleter.get_positron_tile_Layer()

		add_section_on_main_page(filename_of_page_with_detailed_data)

		open(osm_state_page, 'a') {|file|
			file.puts section("mapping_crossing_cycleability", "h2")
			file.puts I18n.t("uncycleable_crossing_mapping_progress")
			file.puts get_progress_bar(@mapped_percent)
			file.puts '<a href="./' + debug_filename + '">' + I18n.t("more_including_map") + '</a>'
		}
	end
end