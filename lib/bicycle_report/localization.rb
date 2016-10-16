def load_localization(language)
	I18n.enforce_available_locales = true
	I18n.load_path = [File.expand_path(File.dirname(__FILE__))+'/translation.yml']
	I18n.backend.load_translations
	I18n.locale=language
end
 
