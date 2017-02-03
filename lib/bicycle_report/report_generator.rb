# encoding: UTF-8
require_relative 'localization'

class ReportGenerator
	def initialize(lat_min, lat_max, lon_min, lon_max)
		@lat_min = lat_min
		@lat_max = lat_max
		@lon_min = lon_min
		@lon_max = lon_max
		set_center_point()
		@starting_zoom = 12

		@sidebar_width_percent = 30
		@map_width_percent = 100-@sidebar_width_percent
	end

	def set_language(language_code)
		load_localization(language_code)
	end

	def set_center_point()
		@center_lat = (@lat_min+@lat_max)/2
		@center_lon = (@lon_min+@lon_max)/2
	end

	def overpass_bb()
		return "#{@lat_min},#{@lon_min},#{@lat_max},#{@lon_max}"
	end

	def enclose(text, tag)
		return "\n<#{tag}>#{text}</#{tag}>\n"
		return text
	end

	def section(text_identifier, tag)
		return enclose(I18n.t(text_identifier), tag)
	end

	def get_progress_bar(percent, description=nil)
		bar = "<div class=\"round-colored\">"
		bar += "<div style=\"width: #{percent}%;\">#{percent}% </div>"
		bar += "</div>"
		if description != nil
			bar += "<div id=\"progressBarDescription\">"
			bar += enclose(description, "p")
			bar += "</div>"
		end
		return bar
	end

	def get_progress_bar_for_missing_data(description=nil)
		bar = "<div id=\"progressBar\" class=\"round-missing-data\">"
		bar += "<div>?% </div>"
		bar += "</div>"
		if description != nil
			bar += enclose(description, "p")
		end
		return bar
	end

	def start_writing_page(filename, title_string_name)
		open(filename, 'w') {|file|
			file.puts "<!DOCTYPE html>
		<html>
		<head>
			<title>" +  I18n.t(title_string_name) + "</title>
			<meta charset=\"utf-8\" />
			<link rel=\"stylesheet\" type=\"text/css\" href=\"./" + css_filename + "\" />
		</head>
		<body>
		<div id=\"full-page-content\">"
			file.puts section(title_string_name, "h1")
		}
	end

	def start_writing_summary_pages
		start_writing_page(main_page, "main_page_title")
		open(main_page, 'a') {|file|
			file.puts section("main_page_subtitle", "h1")
		}

		start_writing_page(osm_state_page, "osm_state_summary_title")

		open(osm_state_page, 'a') {|file|
			file.puts section("osm_data_quality_completness_title", "h2")
			file.puts I18n.t("osm_data_quality_completness")
			file.puts get_progress_bar_for_missing_data
		}
	end

	def finish_writing_summary_pages
		open(main_page, 'a') {|file|
			file.puts write_about_other_sources_of_cycling_information
		}

		finish_writing_page(main_page)
		finish_writing_page(osm_state_page)
	end

	def register_linkable_source(url)
		if @other_sources == nil
			@other_sources = ""
		end
		link = '<a href="' + url + '">' + url + '</a>'
		@other_sources += enclose(link, "p")
	end

	def write_about_other_sources_of_cycling_information
		if @other_sources == nil
			return
		end
		returned = ""
		returned += section("other_sources_of_cycling_information_title", "h2")
		returned += @other_sources
		return returned
	end

	def finish_writing_page(filename)
		open(filename, 'a') {|file|
			file.puts "</div>"
			file.puts "</body>"
			file.puts "</html>"
		}
	end

	def copy_css
		open(css_filename, 'w') {|file|
			file.puts(get_css)
		}
	end

	def main_page
		return 'index.html'
	end

	def osm_state_page
		return 'osm_summary.html'
	end
end