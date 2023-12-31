//
//  AWERepoVoiceChangerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import <CreationKitArch/ACCRepoVoiceChangerModel.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCVoiceEffectSegment;

@interface AWERepoVoiceChangerModel : ACCRepoVoiceChangerModel

// multi-section voice effect
@property (nonatomic, strong, nullable) NSArray<ACCVoiceEffectSegment *> *voiceEffectSegments;

- (ACCVoiceEffectType)voiceEffectType;

- (NSString *)voiceEffectIDs;

- (BOOL)isEqualToObject:(AWERepoVoiceChangerModel *)object;

@end

@interface AWEVideoPublishViewModel (AWERepoVoiceChanger)
 
@property (nonatomic, strong, readonly) AWERepoVoiceChangerModel *repoVoiceChanger;
 
@end

NS_ASSUME_NONNULL_END
