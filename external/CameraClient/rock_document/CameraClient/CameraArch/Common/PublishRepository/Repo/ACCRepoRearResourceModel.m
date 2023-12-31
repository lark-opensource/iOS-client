//
//  ACCRepoRearResourceModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2021/4/8.
//

#import "ACCRepoRearResourceModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoRearResource) <ACCRepositoryElementRegisterCategoryProtocol>
 
@end

@implementation AWEVideoPublishViewModel (RepoRearResource)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoRearResourceModel.class];
    return info;
}

- (ACCRepoRearResourceModel *)RepoRearResource
{
    ACCRepoRearResourceModel *rearResourceModel = [self extensionModelOfClass:ACCRepoRearResourceModel.class];
    NSAssert(rearResourceModel, @"extension model should not be nil");
    return rearResourceModel;
}

@end

@interface ACCRepoRearResourceModel () <NSCopying, ACCRepositoryTrackContextProtocol>

@end

@implementation ACCRepoRearResourceModel

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoRearResourceModel *model = [[ACCRepoRearResourceModel alloc] init];
    model.stickerIDArray = self.stickerIDArray;
    model.musicModel = self.musicModel;
    model.gradeKey = self.gradeKey;
    model.shouldStopLoadWhenfetchMusicError = self.shouldStopLoadWhenfetchMusicError;
    model.musicSelectFrom = self.musicSelectFrom;
    model.musicSelectPageName = self.musicSelectPageName;
    model.propSelectFrom = self.propSelectFrom;
    return model;
}

#pragma mark - ACCRepositoryTrackContextProtocol


@end

#pragma mark - draft


