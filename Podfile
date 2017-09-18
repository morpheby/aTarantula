use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'

platform :osx, '10.11'

target 'TarantulaPluginCore' do
    pod 'CrossroadRegex', :git => 'https://github.com/morpheby/Regex.git'
    pod 'Kanna', :git => 'https://github.com/morpheby/Kanna.git'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CONFIGURATION_BUILD_DIR'] = '$PODS_CONFIGURATION_BUILD_DIR'
    end
  end
end
