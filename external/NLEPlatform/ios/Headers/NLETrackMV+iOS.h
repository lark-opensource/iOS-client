//
//  NLETrackMV+iOS.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/11.
//

#import <Foundation/Foundation.h>
#import "NLETrack+iOS.h"
#import "NLEResourceNode+iOS.h"
#import "NLEMVExternalAlgorithmResult+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLETrackMV_OC : NLETrack_OC

/// mv资源包
@property (nonatomic, strong) NLEResourceNode_OC *mv;

/// 是否设置随MV随单个视频时长变化
@property (nonatomic, assign) BOOL singleVideo;

/// MV模板分辨率 NLESegmentMVResolution
@property (nonatomic, assign) NLESegmentMVResolution mvResolution;

/// 算法路径
@property (nonatomic, strong) NLEResourceNode_OC *algorithm;

/// 背景分割
@property (nonatomic, copy) NSArray<NLEMVExternalAlgorithmResult_OC *> *algorithmResults;

@end

NS_ASSUME_NONNULL_END
