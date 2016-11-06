require_relative '../lib/bicycle_report'

def test_run(lat_min, lat_max, lon_min, lon_max)
  generator = ReportGenerator.new(lat_min, lat_max, lon_min, lon_max)
  generator.set_language(:pl)
  expect(generator.start_writing_summary_pages).to eq(nil)
  expect(generator.start_writing_summary_pages).to eq(nil)
  bicycle_ways = BicycleWayRaportGenerator.new(lat_min, lat_max, lon_min, lon_max)
  bicycle_ways.process([], [])
  crossing = CrossingReportGenerator.new(lat_min, lat_max, lon_min, lon_max)
  crossing.generate_html_files_about_crossings
  bicycle_parking = BicycleParkingRaportGenerator.new(lat_min, lat_max, lon_min, lon_max)
  bicycle_parking.generate_statistics_about_bicycle_parkings
  generator.copy_css()
  generator.finish_writing_summary_pages()
end

RSpec.describe ReportGenerator do
  describe "#start_writing_summary_pages" do
    it "does not crash" do
      lat_min = 50.00
      lat_max = 50.12
      lon_min = 19.78
      lon_max = 20.09
      test_run(lat_min, lat_max, lon_min, lon_max)
    end
    it "does not crash on empty data" do
      lat_min = -55.9284
      lat_max = -55.9285
      lon_min = -129.3050
      lon_max = -129.3051
      test_run(lat_min, lat_max, lon_min, lon_max)
    end
  end
end 
