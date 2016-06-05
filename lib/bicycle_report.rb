# encoding: UTF-8
require 'i18n'
require 'leafleter'
require 'overhelper'
require 'rest-client'
require 'persistent-cache'
require 'digest/sha1'
require 'uri'

require_relative 'bicycle_report/bicycle_parking.rb'
require_relative 'bicycle_report/bicycle_ways.rb'
require_relative 'bicycle_report/crossing.rb'
require_relative 'bicycle_report/report_generator.rb'