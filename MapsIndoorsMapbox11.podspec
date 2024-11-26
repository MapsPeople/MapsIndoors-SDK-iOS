Pod::Spec.new do |s|
  s.name = "MapsIndoorsMapbox11"
  s.version = '4.6.4-beta.2'
  s.summary = 'Library making the MapsIndoors experience available to your iOS users.'
  s.description = "The MapsIndoors SDK enables you to integrate everything at your venue, like people, goods, offices, shops, rooms and buildings with the mapping, positioning and wayfinding technologies provided in the MapsIndoors platform. We make the MapsIndoors platform available to interested businesses and/or partners. So if you think you should be one of them, please call us or send us an email. Meanwhile, you are most welcome to check out the demo project using 'pod try MapsIndoors'."

  s.homepage = "https://www.mapspeople.com/mapsindoors"
  s.license = { type: 'Commercial', text: "Copyright 2016-#{Time.now.year} by MapsPeople A/S" }
  s.documentation_url = 'https://docs.mapsindoors.com/getting-started/ios/'
  s.changelog = "https://github.com/MapsPeople/MapsIndoors-SDK-iOS/blob/main/CHANGELOG.md"

  s.author = { 'MapsPeople' => 'info@mapspeople.com' }
  
  s.source = { http: "https://github.com/MapsPeople/MapsIndoors-SDK-iOS/releases/download/#{s.version.to_s}/MapsIndoorsMapbox11.zip" }

  s.platform = :ios, "14.0"
  s.ios.deployment_target = '14.0'
  s.swift_version = "5.9"
  s.framework = "MapKit"

  s.ios.source_files = "MapBoxProvider-v11/**/**"
  s.module_name = "MapsIndoorsMapbox"

  s.dependency 'MapsIndoorsCore', s.version.to_s
  s.dependency 'MapboxMaps', '11.7.0'
end
