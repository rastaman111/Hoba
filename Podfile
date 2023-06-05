source 'https://github.com/CocoaPods/Specs.git'
source 'https://git.yoomoney.ru/scm/sdk/cocoa-pod-specs.git'

platform :ios, '12.0'

project 'Hoba-Fitness.xcodeproj'
workspace 'Hoba-Fitness.xcworkspace'

def google_utilites
  pod 'GoogleUtilities/AppDelegateSwizzler'
  pod 'GoogleUtilities/Environment'
  pod 'GoogleUtilities/ISASwizzler'
  pod 'GoogleUtilities/Logger'
  pod 'GoogleUtilities/MethodSwizzler'
  pod 'GoogleUtilities/NSData+zlib'
  pod 'GoogleUtilities/Network'
  pod 'GoogleUtilities/Reachability'
  pod 'GoogleUtilities/UserDefaults'
  pod 'GTMSessionFetcher'
end

target 'Hoba-Fitness' do
use_frameworks!

    google_utilites

#  pod 'YooKassaPayments', :path => './'
#  pod 'CardIO', :path => './CardIO'

    pod 'YooKassaPayments',
	:git => 'https://git.yoomoney.ru/scm/sdk/yookassa-payments-swift.git',
	:tag => '6.8.0'
    pod 'CardIO'

    pod 'YooMoneyCoreApi', '~> 2.1.0'
    pod 'MoneyAuth'    
    pod 'ASDKCore'
    pod 'ASDKUI'

    pod 'APESuperHUD'
    pod 'Alamofire', '~> 4.7.2'

    pod 'Siren'

    pod 'SwiftyJSON'

    pod 'JWTDecode', '~> 2.1'

    pod 'SDWebImage'
    pod 'PASImageView'
    pod 'INSPhotoGallery'
    pod 'INSNibLoading'

    pod 'DSGradientProgressView'

    pod 'GoogleMaps'
    pod 'GooglePlaces'
    pod 'Polyline', '~> 4.0'
    pod 'Firebase/Core'
    pod 'Firebase/Analytics'
    pod 'Firebase/Messaging'

    pod 'IQKeyboardManager', '6.5.6'
    
    pod 'PhoneNumberKit', :git => 'https://github.com/marmelroy/PhoneNumberKit'

    pod 'BEMCheckBox'
    pod 'Cosmos', '~> 18.0'
    pod 'Toast-Swift', '~> 5.0.0'

    pod 'YandexMobileMetricaPush/Dynamic', '0.8.0'
    pod 'YandexMobileMetrica/Dynamic', '~> 3.12.0'

end

post_install do |installer|
  puts "Turn off build_settings 'Require Only App-Extension-Safe API' on all pods targets"
  puts "Turn on build_settings 'Supress swift warnings' on all pods targets"
  puts "Turn off build_settings 'Documentation comments' on all pods targets"
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'
      config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ''
      config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'NO'
      config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
    end
  end
end
