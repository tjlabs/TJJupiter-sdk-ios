
# 버전은 JupiterServiceManager.sdkVersion 하나만 관리한다. podspec 은 그 값을 읽어 쓴다.
sdk_version_file = File.join(__dir__, 'TJJupiterSDK/Classes/JupiterServiceManager.swift')
sdk_version = File.read(sdk_version_file)[/static let sdkVersion = "([^"]+)"/, 1]
raise "sdkVersion not found in #{sdk_version_file}" if sdk_version.nil?

Pod::Spec.new do |s|
  s.name             = 'TJJupiterSDK'
  s.version          = sdk_version
  s.summary          = 'A short description of TJJupiterSDK.'
  s.swift_version    = '5.0'
  s.ios.deployment_target = '15.0'

  s.description      = "TJLabs JupiterSDK for iOS"

  s.homepage         = 'https://www.tjlabscorp.com'
  s.license          = { :type => 'TJLABS', :file => 'LICENSE' }
  s.author           = { 'tjlabs-dev' => 'dev@tjlabscorp.com' }
  s.source           = { :git => 'https://github.com/tjlabs/TJJupiter-sdk-ios.git', :tag => s.version.to_s }
  
  s.static_framework = true
  s.source_files = 'TJJupiterSDK/Classes/**/*'
  s.vendored_frameworks = 'TJJupiterSDK/Frameworks/*.xcframework'
  s.pod_target_xcconfig = { 'SWIFT_OPTIMIZATION_LEVEL' => '-Owholemodule' }

end
