source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '10.0'
use_frameworks!

target 'ucoin' do
  pod 'URLNavigator', '~> 2.0.5'
  pod 'SwiftEntryKit', '~> 0.2'
  pod 'StatusAlert', '~> 0.10.1'
  pod 'SwiftyUserDefaults', '4.0.0-alpha.1'
  pod 'Moya', '~> 11.0'
  pod 'PhoneNumberKit', '~> 2.1'
  pod 'KMNavigationBarTransition', '~> 1.1'
  pod 'SnapKit', '~> 4.0.0'
  pod 'CountryPickerView', '~> 2.1.0'
  pod 'IQKeyboardManagerSwift', '~> 6.0'
  pod 'ObjectMapper', '~> 3.2'
  pod 'moa', '~> 9.0'
  pod 'Toucan', '~> 1.0'
  pod 'NVActivityIndicatorView', '~> 4.2'
  pod 'Reusable', '~> 4.0.2'
  pod 'Eureka', '~> 4.1'
  pod 'ImageRow', '~> 3.1'
  pod 'PullToRefreshKit'
  pod 'ShadowView'
  pod 'Marklight'
  pod 'SwiftyMarkdown'
  pod 'TTSegmentedControl'
  pod 'YPImagePicker'
  pod 'Kingfisher'
  pod 'RAMAnimatedTabBarController'
  pod 'WSTagsField'
  pod 'Qiniu', '~> 7.1'
  pod 'FSPagerView'
  pod 'swiftScan', '~> 1.1'
  pod 'Bartinter'
end

post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings.delete('CODE_SIGNING_ALLOWED')
    config.build_settings.delete('CODE_SIGNING_REQUIRED')
  end 
end

