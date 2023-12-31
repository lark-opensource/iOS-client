//
//  AWERepoVoiceChangerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import "AWERepoVoiceChangerModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCVoiceEffectSegment.h>
#import <CreativeKit/ACCMacros.h>

static BOOL is_string_equal(NSString *a, NSString *b)
{
    if (!a && !b) {
        return YES;
    }
    if (!a || !b) {
        return NO;
    }
    return  [a isEqualToString:b];
}

@interface AWEVideoPublishViewModel (AWERepoVoiceChanger) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoVoiceChanger)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoVoiceChangerModel.class];
	return info;
}

- (AWERepoVoiceChangerModel *)repoVoiceChanger
{
    AWERepoVoiceChangerModel *voiceChangerModel = [self extensionModelOfClass:AWERepoVoiceChangerModel.class];
    NSAssert(voiceChangerModel, @"extension model should not be nil");
    return voiceChangerModel;
}

@end

@interface AWERepoVoiceChangerModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation AWERepoVoiceChangerModel

- (ACCVoiceEffectType)voiceEffectType
{
    if (self.voiceEffectSegments.count) {
        return ACCVoiceEffectTypeMultiSegment;
    } else if (self.voiceChangerID.length) {
        return ACCVoiceEffectTypeWhole;
    }
    return ACCVoiceEffectTypeNone;
}

- (void)clearVoiceEffect
{
    [super clearVoiceEffect];
    
    self.voiceEffectSegments = nil;
}

- (NSString *)voiceEffectIDs
{
    if (self.voiceEffectSegments.count) {
        NSMutableArray *ids = [NSMutableArray array];
        [self.voiceEffectSegments enumerateObjectsUsingBlock:^(ACCVoiceEffectSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.effectId.length) {
                [ids addObject:obj.effectId];
            }
        }];
        if (ids.count) {
            return [ids componentsJoinedByString:@","];
        }
    }
    return self.voiceChangerID;
}

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoVoiceChangerModel *model = [super copyWithZone:zone];
    model.voiceEffectSegments = [self.voiceEffectSegments copy];
    return model;
}

- (BOOL)isEqualToObject:(AWERepoVoiceChangerModel *)object
{
    if (![object isKindOfClass:[AWERepoVoiceChangerModel class]]) {
        return NO;
    }
    if (!is_string_equal(self.voiceChangerID, object.voiceChangerID) ||
        !is_string_equal(self.voiceChangerChallengeID, object.voiceChangerChallengeID) ||
        !is_string_equal(self.voiceChangerChallengeName, object.voiceChangerChallengeName)) {
        return NO;
    }
    if (self.voiceEffectSegments.count != object.voiceEffectSegments.count) {
        return NO;
    }
    for (NSInteger idx = 0; idx < self.voiceEffectSegments.count; ++idx) {
        ACCVoiceEffectSegment *current = self.voiceEffectSegments[idx];
        ACCVoiceEffectSegment *other = object.voiceEffectSegments[idx];
        if (!ACC_FLOAT_EQUAL_TO(current.startTime, other.startTime) ||
            !ACC_FLOAT_EQUAL_TO(current.duration, other.duration) ||
            !ACC_FLOAT_EQUAL_TO(current.startPosition, other.startPosition) ||
            !ACC_FLOAT_EQUAL_TO(current.endPosition, other.endPosition) ||
            !ACC_FLOAT_EQUAL_TO(current.zorder, other.zorder) ||
            !is_string_equal(current.effectId, other.effectId)) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    NSMutableDictionary *params = @{}.mutableCopy;
    // 上报变声特效ID
    params[@"voice_modify_id"] = self.voiceEffectIDs;
    NSInteger voiceSegmentCount;
    NSInteger voiceEffectCount;
    if (self.voiceEffectType == ACCVoiceEffectTypeNone) {
        voiceSegmentCount = -1;
        voiceEffectCount = -1;
    } else if (self.voiceEffectType == ACCVoiceEffectTypeWhole) {
        voiceSegmentCount = 0;
        voiceEffectCount = 0;
    } else {
        voiceSegmentCount = self.voiceEffectSegments.count;
        NSMutableSet *effectSet = [NSMutableSet set];
        [self.voiceEffectSegments enumerateObjectsUsingBlock:^(ACCVoiceEffectSegment * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.effectId) {
                [effectSet addObject:obj.effectId];
            }
        }];
        voiceEffectCount = effectSet.count;
    }
    params[@"voice_modify_section_cnt"] = @(voiceSegmentCount);
    params[@"voice_modify_effect_cnt"] = @(voiceEffectCount);
    return params;
}

@end
