require_relative '../lib/bicycle_report'

RSpec.describe ReportGenerator do
  describe "#start_writing_summary_pages" do
    it "does not crash" do
      lat_min = 50.00
      lat_max = 50.12
      lon_min = 19.78
      lon_max = 20.09
      generator = ReportGenerator.new(lat_min, lat_max, lon_min, lon_max)
      generator.set_language(:pl)
      expect(generator.start_writing_summary_pages).to eq(nil)
    end
  end
end 
