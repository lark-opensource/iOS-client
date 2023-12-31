//
//  LVConstDefinition.h
//  LVTemplate
//
//  Created by zenglifeng on 2019/8/13.
//

#import <CoreMedia/CoreMedia.h>

/*********************** 版本 ************************/
extern NSString * const LVTemplateVersion;

extern NSInteger const LVVideoStabVersion;

/*********************** 常量 ************************/
extern CGFloat const veMaxSmoothIndensityValue;

extern CGFloat const veMaxEyeIndensityValue;

extern CGFloat const veMaxVolume;

extern CGFloat const veDefaultVolume;

// 微秒
extern CGFloat const Microsecond;

/*********************** Error ************************/
extern NSErrorDomain const LVPreprocessErrorDomain;

extern NSErrorDomain const LVPlayerErrorDomain;

extern NSString * const LVPreprocessTag;

extern CGFloat const LVOneFrameDuration;

typedef NS_ERROR_ENUM(LVPreprocessErrorDomain, LVError) {
    LVErrorUnknown                 = -10000,
    LVErrorReverseVideoFailed      = -10001,
    LVErrorVideoNotExisted         = -10002,
    LVErrorVideoTrackIsEmpty       = -10003,
    LVErrorVideopayloadNotExisted  = -10004,
    LVErrorNoVideoData             = -10005,
};

typedef NS_ERROR_ENUM(LVPlayerErrorDomain, LVPlayerError) {
    LVPlayerErrorUnknown                 = -20000,
    LVPlayerGenCoverFailed               = -20001,
};

typedef NS_ENUM(NSInteger, LVPlayerFeatureOrder) {
    LVPlayerFeatureReshapeOrder         = 5000,          // 瘦脸
    LVPlayerFeatureChromaOrder          = 5500,          // 色度抠图
    LVPlayerFeatureLocalAdjustOrder     = 6000,          // 局部调节
    LVPlayerFeatureGlobalAdjustOrder    = 7000,          // 全局调节
    LVPlayerFeatureBeautyOrder          = 8000,          // 磨皮
    LVPlayerFeatureLocalFilterOrder     = 9000,          // 局部滤镜
    LVPlayerFeatureGlobalFilterOrder    = 10000,         // 全局滤镜
    LVPlayerFeatureVideoEffectOrder     = 11000,         // 画面特效
    LVPlayerFeatureVideoMaskOrder       = 12000,         // 视频蒙板
};


/*********************** Feed ************************/

typedef NS_ENUM(NSUInteger, LVTemplateErrorCode) {
    LVTemplateErrorCodeSuccess = 0,             // 成功
};
