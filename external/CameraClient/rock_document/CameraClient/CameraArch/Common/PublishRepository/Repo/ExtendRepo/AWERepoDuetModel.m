//
//  AWERepoDuetModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/23.
//

#import "AWERepoDuetModel.h"
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreationKitArch/ACCChallengeModelProtocol.h>
#import <CreationKitArch/ACCModuleConfigProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

NSString * const kACCDuetLayoutGreenScreen = @"green_screen";

const int kAWEModernVideoEditDuetEnlargeMetric = 10;

@interface AWEVideoPublishViewModel (AWERepoDuet) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoDuet)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoDuetModel.class];
	return info;
}

- (AWERepoDuetModel *)repoDuet
{
    AWERepoDuetModel *duetModel = [self extensionModelOfClass:AWERepoDuetModel.class];
    NSAssert(duetModel, @"extension model should not be nil");
    return duetModel;
}

@end

@implementation AWERepoDuetModel

#pragma mark - public

- (NSString *)sourceAwemeID
{
    if (_sourceAwemeID) {
        return _sourceAwemeID;
    }
    
    return self.duetSource.itemID;
}

- (BOOL)isOldDuet
{
    return !ACC_isEmptyString(self.sourceAwemeID) && ACC_isEmptyString(self.duetLayout);
}

- (NSArray *)challengeNames {
    NSMutableArray *challenges = @[].mutableCopy;
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCModuleConfigProtocol);
    if ([config allowCommerceChallenge]) {
        // 合拍带上商业化挑战
        if (self.isDuet) {
            for (id<ACCChallengeModelProtocol> challenge in self.duetSource.challengeList) {
                if (challenge.isCommerce) {
                    if (challenge.challengeName.length != 0 && ![challenges containsObject:challenge.challengeName]) {
                        [challenges addObject:challenge.challengeName];
                    }
                }
            }
        }
    }
    return challenges.copy;
}

- (NSArray *)challengeIDs {
    NSMutableArray *challenges = @[].mutableCopy;
    // Commerce challenge
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCModuleConfigProtocol);
    if ([config allowCommerceChallenge]) {
        // 合拍带上商业化挑战
        if (self.isDuet) {
            for (id<ACCChallengeModelProtocol> challenge in self.duetSource.challengeList) {
                if (challenge.isCommerce) {
                    if (challenge.itemID.length != 0 && ![challenges containsObject:challenge.itemID]) {
                        [challenges addObject:challenge.itemID];
                    }
                }
            }
        }
    }
    return challenges.copy;
}

- (NSString *)duetIdentifierText
{
    return self.isDuetSing ? @"合唱" : @"合拍";
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AWERepoDuetModel *model = [super copyWithZone:zone];
    model.duetSourceAwemeJSON = self.duetSourceAwemeJSON;
    model.duetSourceVideoFilename = self.duetSourceVideoFilename;
    model.duetOriginID = self.duetOriginID;
    model.hasChallenge = self.hasChallenge;
    model.isDuetSing = self.isDuetSing;
    model.chorusMethod = self.chorusMethod;
    model.useRecommendVolume = self.useRecommendVolume;
    model.bgmVolume = self.bgmVolume;
    model.vocalVolume = self.vocalVolume;
    model.vocalAlign = self.vocalAlign;
    model.soundEffectID = self.soundEffectID;
    model.duetSingTuningJSON = self.duetSingTuningJSON;
    model.duetLayoutMessage = self.duetLayoutMessage;
    model.isDuetUpload = self.isDuetUpload;
    model.duetUploadType = self.duetUploadType;
    return model;
}

- (NSDictionary *)acc_referExtraParams
{
    return @{@"chorus_method" : self.chorusMethod ?: @""};
}

#pragma mark - ACCRepositoryRequestParamsProtocol - Optional

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *param = @{}.mutableCopy;
    param[@"duet_from"] = self.sourceAwemeID;
    param[@"duet_layout"] = self.duetLayout ? : @"";
    param[@"duet_origin"] = self.duetOriginID;
    return param.copy;
}

@end
