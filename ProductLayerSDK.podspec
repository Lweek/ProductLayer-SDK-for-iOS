Pod::Spec.new do |spec|
  spec.name         = 'ProductLayerSDK'
  spec.version      = '0.4.3'
  spec.summary      = "The ultimate product information API, enabling a new breed of product-centric apps."
  spec.homepage     = "https://github.com/ProductLayer/ProductLayer-SDK-for-iOS"
  spec.author       = { "Oliver Drobnik" => "oliver@ProductLayer.com" }
  spec.documentation_url = 'https://developer.productlayer.com/documentation/sdk/'
  spec.social_media_url = 'https://twitter.com/ProductLayer'
  spec.source       = { :git => "https://github.com/ProductLayer/ProductLayer-SDK-for-iOS.git", :tag => spec.version.to_s }
  spec.license      = 'BSD'
  spec.requires_arc = true
  spec.ios.deployment_target = '8.0'
  spec.osx.deployment_target = '10.8'

  spec.subspec 'Core' do |ss|
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.8'
    ss.dependency 'DTFoundation/Core', '~>1.7.4'
    ss.dependency 'DTKeychain', '~>1.0.0'
    ss.dependency 'ProductLayerSDK/PLYEntities'
    ss.ios.dependency 'DTFoundation/UIKit', '~>1.7.4'
    ss.ios.dependency 'DTFoundation/UIKit_BlocksAdditions'
    ss.osx.source_files = 'Core/Source/*.{h,m,swift}'
    ss.ios.source_files = 'Core/Source/*.{h,m,swift}', 'Core/Source/iOS/*.{h,m}'
	ss.ios.frameworks = 'AVFoundation'
  	ss.ios.resource_bundles = { 'ProductLayerSDK' => ['Core/Resources/*'] }
  end

  spec.subspec 'PLYEntities' do |ss|
    ss.ios.deployment_target = '8.0'
    ss.osx.deployment_target = '10.8'
    ss.source_files = 'Core/Source/PLYEntities/*.{h,m,swift}'
  end
end
