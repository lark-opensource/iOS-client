//
//  ACCEditVideoDataDowngrading.h
//  CameraClient
//
//  Created by raomengyun on 2021/4/14.
//

#ifndef ACCEditVideoDataDowngrading_h
#define ACCEditVideoDataDowngrading_h

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"
#import "ACCNLEEditVideoData.h"
#import "ACCVideoDataTranslator.h"
#import "ACCVEVideoData.h"
#import <NLEPlatform/NLEInterface.h>

NS_ASSUME_NONNULL_BEGIN

@class HTSVideoData;

// 根据 ACCEditVideoData 获取 HTSVideoData，不进行翻译逻辑
static inline HTSVideoData *_Nullable acc_videodata_take_hts(ACCEditVideoData *videoData) {
    if ([videoData isKindOfClass:[ACCVEVideoData class]]) {
        return [(ACCVEVideoData *)videoData videoData];
    }
    else if ([videoData isKindOfClass:[ACCNLEEditVideoData class]]) {
        return [(ACCNLEEditVideoData *)videoData videoData];
    }
    else {
        NSCAssert(NO, @"unsupported type");
        return nil;
    }
}

// 根据 ACCEditVideoData 获取 ACCVEVideoData，不进行翻译逻辑
static inline ACCVEVideoData *_Nullable acc_videodata_take_ve(ACCEditVideoData *videoData) {
    HTSVideoData *veVideoData = acc_videodata_take_hts(videoData);
    return [ACCVEVideoData videoDataWithVideoData:veVideoData draftFolder:videoData.draftFolder];
}

// 根据 ACCEditVideoData 获取 ACCVEVideoData
static inline ACCVEVideoData * acc_videodata_make_ve(ACCEditVideoData *videoData) {
    if ([videoData isKindOfClass:[ACCVEVideoData class]]) {
        return (ACCVEVideoData *)videoData;
    }
    else if ([videoData isKindOfClass:[ACCNLEEditVideoData class]]) {
        return [ACCVideoDataTranslator translateWithNLEModel:(ACCNLEEditVideoData *)videoData];
    }
    else {
        NSCAssert(NO, @"unsupported type");
        return nil;
    }
}

// 根据 ACCEditVideoData 获取 HTSVideoData
static inline HTSVideoData * acc_videodata_make_hts(ACCEditVideoData *videoData) {
    return [acc_videodata_make_ve(videoData) videoData];
}

// 根据 ACCEditVideoData 获取 ACCNLEEditVideoData，确定 videoData 是 NLE 类型才调用这个方法，否则会命中断言
static inline ACCNLEEditVideoData *_Nullable acc_videodata_take_nle(ACCEditVideoData *videoData) {
    NSCAssert(videoData, @"videoData cannot be nil");
    if (![videoData isKindOfClass:[ACCNLEEditVideoData class]]) {
        NSCAssert(videoData, @"videoData must be ACCNLEEditVideoData");
        return nil;
    }
    
    return (ACCNLEEditVideoData *)videoData;
}

// 根据 ACCEditVideoData 生成一个 ACCNLEEditVideoData，可能会重新创建 videoData
static inline ACCNLEEditVideoData * acc_videodata_make_nle(ACCEditVideoData *videoData, NLEInterface_OC *nle) {
    if ([videoData isKindOfClass:[ACCVEVideoData class]]) {
        return [ACCVideoDataTranslator translateWithVEModel:(ACCVEVideoData *)videoData nle:nle];
    }
    else if ([videoData isKindOfClass:[ACCNLEEditVideoData class]]) {
        return (ACCNLEEditVideoData *)videoData;
    }
    else {
        NSCAssert(NO, @"unsupported type");
        return nil;
    }
}


// 根据 ACCEditVideoData 判断是不是 NLE
static inline BOOL acc_videodata_is_nle(ACCEditVideoData *videoData) {
    return [videoData isKindOfClass:[ACCNLEEditVideoData class]];
}

static inline void acc_videodata_downgrading(
ACCEditVideoData *videoData,
void (^veBlock)(HTSVideoData *videoData),
void (^nleBlock)(ACCNLEEditVideoData *videoData)) {
    // videodata is nle, but it's class is HTSVideoData, need translate
    if ([videoData isKindOfClass:[ACCVEVideoData class]]) {
        veBlock([(ACCVEVideoData *)videoData videoData]);
    }
    else if ([videoData isKindOfClass:[ACCNLEEditVideoData class]]) {
        nleBlock((ACCNLEEditVideoData *)videoData);
    }
    else {
        NSCAssert(NO, @"unsupported type");
    }
};

static inline id acc_videodata_downgrading_ret(
ACCEditVideoData *videoData,
id (^veBlock)(HTSVideoData *videoData),
id (^nleBlock)(ACCNLEEditVideoData *videoData)) {
    if ([videoData isKindOfClass:[ACCVEVideoData class]]) {
        return veBlock([(ACCVEVideoData *)videoData videoData]);
    }
    else if ([videoData isKindOfClass:[ACCNLEEditVideoData class]]) {
        return nleBlock((ACCNLEEditVideoData *)videoData);
    }
    else {
        NSCAssert(NO, @"unsupported type");
        return nil;
    }
};

NS_ASSUME_NONNULL_END

#endif /* ACCEditVideoDataDowngrading_h */
