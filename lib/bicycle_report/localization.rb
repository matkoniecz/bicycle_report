def load_localization(language)
	I18n.enforce_available_locales = true
	I18n.load_path = Dir['*.yml']
	I18n.backend.load_translations
	I18n.locale=language
end
 
