//
//  AWERepoPropModel.m
//  CameraClient
//
//  Created by haoyipeng on 2020/10/25.
//

#import "AWERepoStickerModel.h"
#import "AWERepoPropModel.h"
#import "AWEVideoFragmentInfo.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoVideoInfoModel.h>

@interface AWEVideoPublishViewModel (AWERepoProp) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoProp)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoPropModel.class];
	return info;
}

- (AWERepoPropModel *)repoProp
{
    AWERepoPropModel *propModel = [self extensionModelOfClass:AWERepoPropModel.class];
    NSAssert(propModel, @"extension model should not be nil");
    return propModel;
}

@end

@implementation AWERepoPropModel

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    AWERepoPropModel *copy = [super copyWithZone:zone];
    copy.localPropId = self.localPropId.copy;
    copy.propId = self.propId.copy;
    copy.propBindMusicIDArray = self.propBindMusicIDArray.copy;
    copy.multiSegPropClipsArray = self.multiSegPropClipsArray;
    copy.liveDuetPostureImagesFolderPath = self.liveDuetPostureImagesFolderPath;
    copy.selectedLiveDuetImageIndex = self.selectedLiveDuetImageIndex;
    return copy;
}

#pragma mark - Public

- (NSArray <NSString *>*)stickerBindedChallengeArray
{
    NSMutableArray *challengeNameArray = [NSMutableArray array];
    // 拍摄页道具
    ACCRepoVideoInfoModel *recordInfoRepoModel = [self.repository extensionModelOfClass:[ACCRepoVideoInfoModel class]];
    for (AWEVideoFragmentInfo *fragmentInfo in recordInfoRepoModel.fragmentInfo.copy) {
        for (AWEVideoPublishChallengeInfo *challengeInfo in fragmentInfo.challengeInfos) {
            if (challengeInfo.challengeName.length > 0 && ![challengeNameArray containsObject:challengeInfo.challengeName]) {
                [challengeNameArray addObject:challengeInfo.challengeName];
            }
        }
    }
    // 编辑页贴纸
    AWERepoStickerModel *stickerModel = [self.repository extensionModelOfClass:AWERepoStickerModel.class];
    [challengeNameArray addObjectsFromArray:[stickerModel infoStickerChallengeNames]];
    
    return challengeNameArray.copy;
}

- (BOOL)isMultiSegPropApplied
{
    return self.multiSegPropClipsArray > 0;
}


@end
