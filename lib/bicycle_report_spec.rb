require 'bicycle_report'

RSpec.describe ReportGenerator do
  describe "#start_writing_summary_pages" do
    it "does not crash" do
		lat_min = 50.00
		lat_max = 50.12
		lon_min = 19.78
		lon_max = 20.09
      game = ReportGenerator.new(lat_min, lat_max, lon_min, lon_max)
      expect(game.start_writing_summary_pages).to eq(nil)
    end
  end
end 
