//
//  ACCVoiceEffectSegment.h
//  Pods
//
//  Created by Shen Chen on 2020/8/7.
//

#import <Foundation/Foundation.h>
#import "ACCSegmentBlender.h"

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;

@interface ACCVoiceEffectSegment : NSObject<NSCoding, ACCSegmentItem>
@property (nonatomic, assign) NSTimeInterval startTime;
@property (nonatomic, assign) NSTimeInterval duration;
@property (nonatomic, strong) IESEffectModel *effect;
@property (nonatomic, strong, nullable) NSString *effectId;

@property (nonatomic, assign) double startPosition;
@property (nonatomic, assign) double endPosition;
@property (nonatomic, assign) CGFloat zorder;

- (instancetype)initWithStartTime:(NSTimeInterval)startTime duration:(NSTimeInterval)duration effect:(IESEffectModel *)effect;
- (BOOL)canMergeWith:(ACCVoiceEffectSegment *)item;
@end


NS_ASSUME_NONNULL_END
