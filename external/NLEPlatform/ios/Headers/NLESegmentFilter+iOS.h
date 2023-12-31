//
//  NLESegmentFilter+iOS.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/8.
//

#import "NLESegment+iOS.h"
#import "NLEResourceNode+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentFilter_OC : NLESegment_OC

/// 滤镜强度，亮度值，对比度，饱和度，锐化，高光，色温
@property (nonatomic, assign) float intensity;

/// 滤镜名称，用于展示
@property (nonatomic, copy) NSString *filterName;

/// 滤镜资源
@property (nonatomic, copy) NLEResourceNode_OC *effectSDKFilter;

/// 构造初始化一个变声用的filter, 内部会对filterName进行赋值为 NLE_AUDIO_COMMON_FILTER
+ (instancetype)audioFilterSegment;

/// 是否是音频变声滤镜
- (BOOL)isAudioFilterSegment;

- (BOOL)isAudioDSPFilterSegment;

- (BOOL)isAudioBalanceFilterSegment;

- (BOOL)isAudioVolumeFilterSegment;

/// 类型：滤镜、调节
- (NLEResourceType)getType;

/// 滤镜资源
- (NLEResourceNode_OC*)getResNode;

@end

NS_ASSUME_NONNULL_END
