# NLEEditor-iOS

[![CI Status](https://img.shields.io/travis/bytedance/NLEEditor-iOS.svg?style=flat)](https://travis-ci.org/bytedance/NLEEditor-iOS)
[![Version](https://img.shields.io/cocoapods/v/NLEEditor-iOS.svg?style=flat)](https://cocoapods.org/pods/NLEEditor-iOS)
[![License](https://img.shields.io/cocoapods/l/NLEEditor-iOS.svg?style=flat)](https://cocoapods.org/pods/NLEEditor-iOS)
[![Platform](https://img.shields.io/cocoapods/p/NLEEditor-iOS.svg?style=flat)](https://cocoapods.org/pods/NLEEditor-iOS)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

```ruby
pod 'NLEPlatform', :git => 'git@code.byted.org:ies/NLEPlatform.git', :subspecs => ['TOBAdapter'], :branch => 'feature/ck/2.4'
pod 'DVETrackKit', :git => 'git@code.byted.org:ies/DVETrackKit.git', :subspecs => ['TOBAdapter'], :branch => 'develop'
```
## Structure
以下结构根据subspec划分，具体可看NLEEditor.podspec
```
Core -- 核心的功能逻辑
TOBAdapter -- 依赖了NLEPlatform的重演能力
SubTitleRecognize -- 语音转字幕相关能力
DVEAlbum -- 相册能力
```

## Installation


```ruby
pod 'NLEEditor', :git => 'git@code.byted.org:ugc/NLEEditor-iOS.git', :subspecs => ['TOBAdapter'], :branch => 'develop'

#推荐使用以下版本的依赖库
pod 'DVEInject', '0.0.1'
pod 'SGPagingView', '1.7.1'
pod 'KVOController','1.2.0'
pod 'Masonry','1.1.0'
pod 'ReactiveObjC', '3.1.1'
pod 'YYWebImage', '1.0.5'
pod 'YYImage', '1.0.4'
pod 'YYModel', '1.0.4'
pod 'MBProgressHUD', '1.2.0'
pod 'lottie-ios', '2.5.3'
pod 'SDWebImage', '5.11.1'
pod 'Toast', '4.0.0'
pod 'DoraemonKit', '3.0.7',:subspecs => ['Core','WithMLeaksFinder']
pod 'MJExtension' , '3.1.15.7'
pod 'PocketSVG', '2.7.0'


#若要引入语音转字幕能力，需要额外引入并推荐使用以下版本的依赖库
pod 'SpeechEngineTts', '1.0.10'
pod 'boringssl', '0.1.4'

#若要引入相册能力，需要额外引入并推荐使用以下版本的依赖库
pod 'IGListKit', '4.0.0'
pod 'IGListDiffKit', '4.0.0'

```

## Developer guide
开发接入可看该文档
https://bytedance.feishu.cn/docs/doccncCCJwBAuCCs3j9djKY4jPh

## Author

bytedance, bytedance@bytedance.com


## License

NLEEditor-iOS is available under the MIT license. See the LICENSE file for more info.
