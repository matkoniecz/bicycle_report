# encoding: UTF-8
require 'i18n'
require 'leafleter'
require 'overhelper'
require 'rest-client'
require 'persistent-cache'
require 'digest/sha1'
require 'uri'

#probably this horribly hack should be solved in some other way
module ::I18n
  class << self
    def htmlify_newlines(*args)
      return old_translate(*args).gsub("\n", "<br>")
    end
    alias :old_translate :translate
    alias :translate :htmlify_newlines
    alias :t :htmlify_newlines
  end
end

require_relative 'bicycle_report/bicycle_parking.rb'
require_relative 'bicycle_report/bicycle_ways.rb'
require_relative 'bicycle_report/crossing.rb'
require_relative 'bicycle_report/get_css.rb'
require_relative 'bicycle_report/report_generator.rb'