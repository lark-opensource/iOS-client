//
//  LVKeyframePool+extention.h
//  VideoTemplate
//
//  Created by zenglifeng on 2020/5/26.
//

#import "LVDraftModels.h"
#import "LVMediaDefinition.h"
#import "LVModelType.h"
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@class LVMediaSegment;
@protocol LVKeyframeProtocol <NSObject>

- (void)applyPropertiesToSegment:(LVMediaSegment *)segment;

@optional
- (void)adjustKeyframePropertiesIfNeeded;

@end

@interface LVKeyframePool (Interface)

- (NSDictionary<NSString*, LVKeyframe*>*)allKeyframes;

@end

@interface LVKeyframe (Interface)<LVCopying, LVKeyframeProtocol>

@property (nonatomic, assign) LVKeyframeType type;

@property (nonatomic, assign) CMTime time;

- (instancetype)initWithType:(LVKeyframeType)type time:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
