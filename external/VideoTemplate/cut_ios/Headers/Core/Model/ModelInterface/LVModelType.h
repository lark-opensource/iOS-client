//
//  LVModelType.h
//  longVideo
//
//  Created by xiongzhuang on 2019/7/16.
//

#import <Foundation/Foundation.h>

/**
 素材类型
 
 - LVPayloadRealTypeVideo: 视频
 - LVPayloadRealTypePhoto: 视频-图片
 - LVPayloadRealTypeMusic: 音乐
 - LVPayloadRealTypeExtractMusic: 提取音乐
 - LVPayloadRealTypeSound: 音效
 - LVPayloadRealTypeRecord: 录音
 - LVPayloadRealTypeImage: 图片资源
 - LVPayloadRealTypeText: 文本
 - LVPayloadRealTypeSubtitle: 识别字幕
 - LVPayloadRealTypeSticker: 贴纸
 - LVPayloadRealTypeFilter: 滤镜
 - LVPayloadRealTypeReshape: 美颜-形变
 - LVPayloadRealTypeBeauty: 美颜-美白
 - LVPayloadRealTypeVideoEffect: 视频特效
 - LVPayloadRealTypeSegmentCanvas: 画布
 - LVPayloadRealTypeCanvasColor: 画布背景颜色
 - LVPayloadRealTypeCanvasImage: 画布背景图片
 - LVPayloadRealTypeCanvasBlur: 画布模糊
 - LVPayloadRealTypeTransition: 转场
 - LVPayloadRealTypeAudioEffect: 变声
 - LVPayloadRealTypeAudioFade: 音频淡入淡出
 - LVPayloadRealTypeBeats: 踩点数据
 - LVPayloadRealTypeTailLeader: 片尾
 - LVPayloadRealTypeAnimation: 贴纸动画
 - LVPayloadRealTypeVideoAnimation: 视频动画
 - LVPayloadRealTypeTextToAudio 文本转语音
 - LVPayloadRealTypeVideoMix 视频混合
 - LVPayloadRealTypeTextToAudio 文本转语音
 - LVPayloadRealTypeLyrics 歌词
 - LVPayloadRealTypeVideoMask 视频蒙版
 - LVPayloadRealTypeSpeed 变速
 - LVPayloadRealTypeChroma 色度抠图
 - LVPayloadRealTypeTextTemplate 文字模板
 - LVPayloadRealTypeGif: 视频-gif
 - LVPayloadRealTypeStretchLeg: 美体-长腿
 - LVPayloadRealTypeRealTimeDenoise: 实时降噪 专业版用到 移动端转成服务端处理好后下载
 */
typedef NS_ENUM(NSUInteger, LVPayloadRealType) {
    LVPayloadRealTypeVideo = 1,
    LVPayloadRealTypePhoto,
    LVPayloadRealTypeMusic,
    LVPayloadRealTypeExtractMusic,
    LVPayloadRealTypeSound,
    LVPayloadRealTypeRecord,
    LVPayloadRealTypeImage,
    
    LVPayloadRealTypeText,
    LVPayloadRealTypeSubtitle,
    LVPayloadRealTypeSticker,
    LVPayloadRealTypeFilter,
    LVPayloadRealTypeReshape,
    LVPayloadRealTypeBeauty,
    LVPayloadRealTypeVideoEffect,
    
    LVPayloadRealTypeBrightness,
    LVPayloadRealTypeContrast,
    LVPayloadRealTypeSaturation,
    LVPayloadRealTypeSharpen,
    LVPayloadRealTypeHighlight,
    LVPayloadRealTypeShadow,
    LVPayloadRealTypeTemperature,
    LVPayloadRealTypeTone,
    LVPayloadRealTypeFade,
    LVPayloadRealTypeLightSensation,
    LVPayloadRealTypeVignetting,
    LVPayloadRealTypeParticle,
    
    LVPayloadRealTypeSegmentCanvas,
    LVPayloadRealTypeCanvasColor,
    LVPayloadRealTypeCanvasImage,
    LVPayloadRealTypeCanvasBlur,
    LVPayloadRealTypeTransition,
    LVPayloadRealTypeAudioEffect,
    LVPayloadRealTypeAudioFade,
    LVPayloadRealTypeBeats,
    LVPayloadRealTypeTailLeader,
    
    LVPayloadRealTypeAnimation,
    
    LVPayloadRealTypeTextEffect,
    LVPayloadRealTypeTextShape,
    
    LVPayloadRealTypeVideoAnimation,
    LVPayloadRealTypeTextToAudio,
    LVPayloadRealTypeVideoMix,
    LVPayloadRealTypeLyrics,
    LVPayloadRealTypeAdjust,
    LVPayloadRealTypeVideoMask,
    LVPayloadRealTypeSpeed,
    LVPayloadRealTypeChroma,
    LVPayloadRealTypeTextTemplate,
    LVPayloadRealTypeGif,
    LVPayloadRealTypeVideoOriginalSound,
    LVPayloadRealTypeStretchLeg,
    LVPayloadRealTypeRealTimeDenoise,
    LVPayloadRealTypeFigure,
    LVPayloadRealTypeFaceEffect
};

/**
 素材类型
 
 - LVPayloadGenericTypeVideo      ：视频素材，包含照片视频、视频
 - LVPayloadGenericTypeAudio      ：音频素材，包含音乐、提取音乐、录音、原声
 - LVPayloadGenericTypeImages     ：图片贴纸素材
 - LVPayloadGenericTypeTailLeader ：片尾素材
 - LVPayloadGenericTypeText       ：文本素材，包含普通文本、字幕
 - LVPayloadGenericTypeEffect     ：特效素材，包含画面特效、滤镜、美颜、形变、视频调节小项、视频混合
 - LVPayloadGenericTypeSticker    ：贴纸素材
 - LVPayloadGenericTypeCanvas     ：画布素材，包含颜色、背景图片、高斯模糊
 - LVPayloadGenericTypeTransition ：转场素材
 - LVPayloadGenericTypeAudioEffect：音效素材
 - LVPayloadGenericTypeAudioFade  ：淡入淡出素材
 - LVPayloadGenericTypeAudioEffect：音效素材
 - LVPayloadGenericTypeBeats      ：打点素材
 - LVPayloadGenericTypeAnimation  ：动画素材
 - LVPayloadGenericTypePlaceholder：占位素材
 - LVPayloadGenericTypeVideoMask  ：蒙版素材
 - LVPayloadGenericTypeSpeed      : 速度素材
 - LVPayloadGenericTypeChroma     : 色度抠图素材
 - LVPayloadGenericTypeTextTemplate: 文字模板素材
 */
typedef NS_ENUM(NSUInteger, LVPayloadGenericType) {
    LVPayloadGenericTypeUnknown = 1,
    LVPayloadGenericTypeVideo,
    LVPayloadGenericTypeAudio,
    LVPayloadGenericTypeImage,
    LVPayloadGenericTypeTailLeader,
    LVPayloadGenericTypeText,
    LVPayloadGenericTypeEffect,
    LVPayloadGenericTypeSticker,
    LVPayloadGenericTypeCanvas,
    LVPayloadGenericTypeTransition,
    LVPayloadGenericTypeAudioEffect,
    LVPayloadGenericTypeAudioFade,
    LVPayloadGenericTypeBeats,
    LVPayloadGenericTypeAnimation,
    LVPayloadGenericTypePlaceholder,
    LVPayloadGenericTypeVideoMask,
    LVPayloadGenericTypeSpeed,
    LVPayloadGenericTypeChroma,
    LVPayloadGenericTypeTextTemplate,
    LVPayloadGenericTypeRealtimeDenoise
};

/**
 对齐画布/视频
 
 - LVMutableConfigAlignModeCanvas: 对齐画布
 - LVMutableConfigAlignModeVideo: 对齐视频
 */
typedef NS_ENUM(NSUInteger, LVMutableConfigAlignMode) {
    LVMutableConfigAlignModeCanvas = 1,
    LVMutableConfigAlignModeVideo,
};

/**
 可变素材支持平台
 
 - LVMutablePayloadPlaformSupportBoth: iOS+Android
 - LVMutablePayloadPlaformSupportIos: iOS
 - LVMutablePayloadPlaformSupportAndroid: Android
 */
typedef NS_ENUM(NSUInteger, LVMutablePayloadPlatformSupport) {
    LVMutablePayloadPlatformSupportBoth,
    LVMutablePayloadPlatformSupportiOS,
    LVMutablePayloadPlatformSupportAndroid,
};

extern LVPayloadGenericType genericType(LVPayloadRealType realType);

/**
关键帧类型

 - LVKeyframeTypeNone：未知类型
 - LVKeyframeTypeVideo：视频关键帧
 - LVKeyframeTypeAudio：音频关键帧
 - LVKeyframeTypeText：文字关键帧
 - LVKeyframeTypeSticker：贴纸关键帧
 - LVKeyframeTypeFilter：滤镜关键帧
 - LVKeyframeTypeAdjust：调节关键帧
*/
typedef NS_ENUM(NSUInteger, LVKeyframeType) {
    LVKeyframeTypeNone = 0,
    LVKeyframeTypeVideo = 1,
    LVKeyframeTypeAudio,
    LVKeyframeTypeText,
    LVKeyframeTypeSticker,
    LVKeyframeTypeFilter,
    LVKeyframeTypeAdjust,
};
