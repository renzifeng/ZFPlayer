#
# Be sure to run `pod lib lint ZFPlayer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'ZJXZFPlayer'
s.version          = '3.2.6'
s.summary          = 'A good player made by renzifeng'
s.homepage         = 'https://github.com/oldBlackComing/ZFPlayer'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'zhoujiaxing' => '884548958@qq.com' }
s.source           = { :git => 'https://github.com/oldBlackComing/ZFPlayer.git', :tag => s.version.to_s }
s.social_media_url = 'http://weibo.com/zifeng1300'
s.ios.deployment_target = '7.0'
s.requires_arc = true

s.default_subspec = 'Core'

s.subspec 'Core' do |core|
core.source_files = 'ZFPlayer/Classes/Core/**/*'
core.public_header_files = 'ZFPlayer/Classes/Core/**/*.h'
core.frameworks = 'UIKit', 'MediaPlayer', 'AVFoundation'
end

s.subspec 'ControlView' do |controlView|
controlView.source_files = 'ZFPlayer/Classes/ControlView/**/*.{h,m}'
controlView.public_header_files = 'ZFPlayer/Classes/ControlView/**/*.h'
controlView.resource = 'ZFPlayer/Classes/ControlView/ZFPlayer.bundle'
controlView.dependency 'ZFPlayer/Core'
end

s.subspec 'AVPlayer' do |avPlayer|
avPlayer.source_files = 'ZFPlayer/Classes/AVPlayer/**/*.{h,m}'
avPlayer.public_header_files = 'ZFPlayer/Classes/AVPlayer/**/*.h'
avPlayer.dependency 'ZFPlayer/Core'
end

s.subspec 'ijkplayer' do |ijkplayer|
ijkplayer.source_files = 'ZFPlayer/Classes/ijkplayer/*.{h,m}'
ijkplayer.public_header_files = 'ZFPlayer/Classes/ijkplayer/*.h'
ijkplayer.dependency 'ZFPlayer/Core'
ijkplayer.dependency 'IJKMediaFramework'
ijkplayer.ios.deployment_target = '8.0'
end

s.subspec 'KSYMediaPlayer' do |ksyMediaPlayer|
ksyMediaPlayer.source_files = 'ZFPlayer/Classes/KSYMediaPlayer/*.{h,m}'
ksyMediaPlayer.public_header_files = 'ZFPlayer/Classes/KSYMediaPlayer/*.h'
ksyMediaPlayer.dependency 'ZFPlayer/Core'
ksyMediaPlayer.dependency 'KSYMediaPlayer'
ksyMediaPlayer.pod_target_xcconfig = {
'ARCHS[sdk=iphonesimulator*]' => '$(ARCHS_STANDARD_64_BIT)'
}
end

end
