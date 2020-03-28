class StaticPagesController < ApplicationController
	def index
	end

	def download_catalogue
		@data_hash = Hash.new{|h,k| h[k] = []}
		orphan_planets_count = 0
    star_temperature = 0
    orbiting_planet = ''
    report_content = ''
    orphan_planets = ''
    hot_star = ''

    data_set = JSON.parse(`curl https://gist.githubusercontent.com/joelbirchler/66cf8045fcbb6515557347c05d789b4a/raw/9a196385b44d4288431eef74896c0512bad3defe/exoplanets`)
    return "No Data Set" if (data_set.nil? || data_set.length == 0)

    data_set.each do|items|
      # Find the orphan planets
      orphan_planets_count = orphan_planets_count + 1 if items['TypeFlag'] == 3

      # Orbiting Planet
      if star_temperature < items['HostStarTempK'].to_i
        star_temperature = items['HostStarTempK'].to_i
        orbiting_planet = items['PlanetIdentifier']
      end

      next if items['RadiusJpt'].to_f == 0 || items['DiscoveryYear'].to_i == 0

      unless items['DiscoveryYear'].nil?
        if items['RadiusJpt'].to_f < 1.0
          @data_hash[items['DiscoveryYear']][0] = (@data_hash[items['DiscoveryYear']][0].nil? ? 0 : @data_hash[items['DiscoveryYear']][0]) + 1
        elsif items['RadiusJpt'].to_f < 2.0
          @data_hash[items['DiscoveryYear']][1] = (@data_hash[items['DiscoveryYear']][1].nil? ? 0 : @data_hash[items['DiscoveryYear']][1]) + 1
        elsif items['RadiusJpt'].to_f > 2.0
          @data_hash[items['DiscoveryYear']][2] = (@data_hash[items['DiscoveryYear']][2].nil? ? 0 : @data_hash[items['DiscoveryYear']][2]) + 1
        end
      end
    end

    @data_hash['count_orphan'] = orphan_planets_count
    @data_hash['hot_star'] = orbiting_planet

    @data_hash.each do|key,value|
      if key == 'count_orphan'
        orphan_planets =  "The number of Orphan Planets: #{@data_hash['count_orphan']} \n"
      elsif key == 'hot_star'
        hot_star = "The Name of the Planet Identifier: #{@data_hash['hot_star']}"
      else
        value[0].nil? ? value[0] = 0 : value[0] 
        value[1].nil? ? value[1] = 0 : value[1] 
        value[2].nil? ? value[2] = 0 : value[2] 

        report_content += "Small Planets: #{value[0]}, Medium Planets: #{value[1]} and Large Planets: #{value[2]} are discovered in => #{key} \n"
      end
    end

		title = "Exoplanet Catalogue \n\n\n"
    respond_to do |format|
 			format.pdf do
        pdf = Prawn::Document.new
        pdf.text (title + report_content + orphan_planets + hot_star)
        send_data pdf.render,
          filename: "exoplanet-#{Time.now}.pdf",
          type: 'application/pdf',
          disposition: 'attachment'
      end
  	end
	end
end