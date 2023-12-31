//
//  HTSVideoData+AWEAIVideoClipInfo.h
//  Pods
//
//  Created by wang ya on 2019/8/2.
//

#import <TTVideoEditor/HTSVideoData.h>
#import "ACCEditVideoData.h"

typedef NS_ENUM(NSUInteger, ACCVideoDataClipType) {
    ACCVideoDataClipTypeDefault,
    ACCVideoDataClipTypeAI,
};

NS_ASSUME_NONNULL_BEGIN

@interface HTSVideoData (AWEAIVideoClipInfo)

@property (nonatomic, assign) AWEAIVideoClipInfoResolveType studio_videoClipResolveType;

@end

NS_ASSUME_NONNULL_END
