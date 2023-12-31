//
//  ACCVoiceEffectSegment.m
//  Pods
//
//  Created by Shen Chen on 2020/8/7.
//

#import "ACCVoiceEffectSegment.h"
#import "ACCPublishRepositoryElementProtocols.h"

#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <EffectPlatformSDK/EffectPlatform.h>

@interface ACCVoiceEffectSegment()
@property (nonatomic, strong) NSString *internalEffectId;
@end

@implementation ACCVoiceEffectSegment

@dynamic startPosition, endPosition;

- (instancetype)initWithStartTime:(NSTimeInterval)startTime duration:(NSTimeInterval)duration effect:(IESEffectModel *)effect
{
    self = [super init];
    if (self) {
        self.startTime = startTime;
        self.duration = duration;
        self.effect = effect;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSTimeInterval startTime = [coder decodeDoubleForKey:@"startTime"];
    NSTimeInterval duration = [coder decodeDoubleForKey:@"duration"];
    NSString *effectId = [coder decodeObjectForKey:@"effectId"];
    self = [super init];
    if (self) {
        self.startTime = startTime;
        self.duration = duration;
        self.internalEffectId = effectId;
    }
    return self;
}

- (NSString *)effectId {
    return self.effect.effectIdentifier ? : self.internalEffectId;
}

- (void)setEffectId:(NSString *)effectId
{
    _internalEffectId = effectId;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    [coder encodeDouble:self.startTime forKey:@"startTime"];
    [coder encodeDouble:self.duration forKey:@"duration"];
    [coder encodeObject:self.effectId forKey:@"effectId"];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    ACCVoiceEffectSegment *segment = [[self.class allocWithZone:zone] init];
    segment.startTime = self.startTime;
    segment.duration = self.duration;
    segment.effect = self.effect;
    segment.zorder = self.zorder;
    return segment;
}

- (double)startPosition
{
    return self.startTime;
}

- (void)setStartPosition:(double)startPosition
{
    self.startTime = startPosition;
}

- (double)endPosition
{
    return self.startTime + self.duration;
}

- (void)setEndPosition:(double)endPosition
{
    self.duration = endPosition - self.startTime;
}

- (BOOL)canMergeWith:(ACCVoiceEffectSegment *)item
{
    if (self.effectId.length == 0 && item.effectId.length == 0) {
        return YES;
    }
    return [self.effectId isEqualToString:item.effectId];
}

@end
