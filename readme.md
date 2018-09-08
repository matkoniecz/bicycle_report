Generator of bicycle infrastricture overview for a given area.

Results are based on the OpenStreetMap database and optional additional comments.

Example of a generated website is at https://github.com/matkoniecz/bicycle_map_of_Krakow hosted at https://matkoniecz.github.io/bicycle_map_of_Krakow/

## Data flow

data flow in bicycle_report gem, in increasing detail:

OpenStreetMap -> bicycle report gem -> website with bicycle statistics

OpenStreetMap -> overpass -> overhelper gem -> bicycle report gem -> website with bicycle statistics

OpenStreetMap -> overpass -> overhelper gem -> osm_data_intepreter.rb -> .. -> website with bicycle statistics
