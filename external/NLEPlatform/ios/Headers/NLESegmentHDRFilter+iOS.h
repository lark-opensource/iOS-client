//
//  NLESegmentHDRFilter+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/6/22.
//

#import <Foundation/Foundation.h>
#import "NLESegmentFilter+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentHDRFilter_OC : NLESegmentFilter_OC

/// 抽帧类型
@property (nonatomic, assign) NSInteger frameType;

/// 是否降噪
@property (nonatomic, assign) BOOL denoise;

/// ONE Key HDR 场景下用到
///
/// ASF_MODE_FOR_ON = 0,                           //代表开启锐化
/// ASF_MODE_FOR_20004_OFF = 1,             //代表在20004夜景时关闭锐化
/// ASF_MODE_FOR_NOT_20004_OFF = 2,   //代表在非20004的情况下关闭锐化
/// ASF_MODE_FOR_OFF = 3,                        //代表关闭锐化
@property (nonatomic, assign) NSInteger asfMode;

/// ONE Key HDR 场景下用到
///
/// HDR_MODE_FOR_ON = 0,                                      //代表所有场景开启HDR
/// HDR_MODE_FOR_20001_OFF = 1,                        //代表在20001时关闭HDR
/// HDR_MODE_FOR_20001_OR_20003_OFF = 2,     //代表在20001或20003关闭HDR
/// HDR_MODE_FOR_20004_OFF = 3,                        //代表在20004关闭HDR
/// HDR_MODE_FOR_OFF = 4,                                    //所有case情况关闭HDR
@property (nonatomic, assign) NSInteger hdrMode;

@end

NS_ASSUME_NONNULL_END
