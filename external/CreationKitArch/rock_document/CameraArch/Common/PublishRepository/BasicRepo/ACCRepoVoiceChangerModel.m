//
//  ACCRepoVoiceChangerModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import "ACCRepoVoiceChangerModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoVoiceChanger) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoVoiceChanger)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoVoiceChangerModel.class];
}

- (ACCRepoVoiceChangerModel *)repoVoiceChanger
{
    ACCRepoVoiceChangerModel *voiceChangerModel = [self extensionModelOfClass:ACCRepoVoiceChangerModel.class];
    NSAssert(voiceChangerModel, @"extension model should not be nil");
    return voiceChangerModel;
}

@end

@interface ACCRepoVoiceChangerModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation ACCRepoVoiceChangerModel

- (void)clearVoiceEffect
{
    self.voiceChangerID = nil;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoVoiceChangerModel *model = [[[self class] alloc] init];
    model.voiceChangerID = self.voiceChangerID;
    model.voiceChangerChallengeID = self.voiceChangerChallengeID;
    model.voiceChangerChallengeName = self.voiceChangerChallengeName;
    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    return @{};
}

@end
