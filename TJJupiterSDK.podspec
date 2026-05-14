
Pod::Spec.new do |s|
  s.name             = 'TJJupiterSDK'
  s.version          = '2.0.1'
  s.summary          = 'A short description of TJJupiterSDK.'
  s.swift_version    = '5.0'
  s.ios.deployment_target = '16.0'

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
