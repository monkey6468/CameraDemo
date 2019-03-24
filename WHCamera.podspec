#
#  Be sure to run `pod spec lint WHCamera.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "WHCamera"
  s.version      = "0.0.1"
  s.summary      = "A Library for iOS to use for Camera."
  s.description  = <<-DESC
                    "基于Object-C的iOS纯原生API相机，高度集成，使用快捷简单。可快速集成使用。最低支持iOS7的系统。"
                   DESC
  s.platform     = :ios, "7.0"
  s.homepage     = "https://github.com/1019459067/CameraDemo"
  s.license      = "MIT"
  s.author       = { "xiaoweihua" => "1019459067@qq.com" }
  s.source       = { :git => "https://github.com/1019459067/CameraDemo.git", :tag => "#{s.version}" }
  s.source_files  = "WHCamera/*.{h,m}"
end
