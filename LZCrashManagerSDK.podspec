Pod::Spec.new do |s|
  s.name             = 'LZCrashManagerSDK'
  s.version          = '1.0.0'
  s.summary          = 'A lightweight iOS crash capture and deferred upload SDK.'
  s.description      = <<-DESC
LZCrashManagerSDK is a lightweight iOS SDK for capturing uncaught Objective-C
exceptions, persisting crash reports locally, keeping the crashing thread alive
for a short window, and uploading pending crash reports to a server on next launch.
  DESC

  s.homepage         = 'https://github.com/pop-xiaoli-hub/LZCrashManagerSDK'
  s.license          = { :type => 'MIT' }
  s.author           = { 'pop-xiaoli-hub' => '2397846118@qq.com' }
  s.platform         = :ios, '12.0'
  s.source           = { :git => 'git@github.com:pop-xiaoli-hub/LZCrashManagerSDK.git', :tag => s.version.to_s }

  s.requires_arc     = true
  s.static_framework = true

  s.source_files = 'LZCrashManagerSDK/*.{h,m}'
  s.public_header_files = [
    'LZCrashManagerSDK/LZCrashManagerSDK.h',
    'LZCrashManagerSDK/LZCrashManager.h',
    'LZCrashManagerSDK/LZCrashManagerConfiguration.h',
    'LZCrashManagerSDK/LZCrashReport.h'
  ]

  s.frameworks = 'Foundation'
end
