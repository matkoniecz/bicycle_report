def css_filename
	return "main.css"
end

def get_css
	folder = File.expand_path(File.dirname(__FILE__))
	return File.read(folder+"/"+css_filename)
end