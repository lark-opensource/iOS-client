//
//  ACCRepoVoiceChangerModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCVoiceEffectType) {
    ACCVoiceEffectTypeNone = 0,
    ACCVoiceEffectTypeWhole,
    ACCVoiceEffectTypeMultiSegment
};

@class ACCVoiceEffectSegment;

@interface ACCRepoVoiceChangerModel : NSObject <NSCopying>

@property (nonatomic, copy, nullable) NSString *voiceChangerID;
@property (nonatomic, copy, nullable) NSString *voiceChangerChallengeID;
@property (nonatomic, copy, nullable) NSString *voiceChangerChallengeName;

- (void)clearVoiceEffect;

@end

@interface AWEVideoPublishViewModel (RepoVoiceChanger)
 
@property (nonatomic, strong, readonly) ACCRepoVoiceChangerModel *repoVoiceChanger;
 
@end

NS_ASSUME_NONNULL_END
