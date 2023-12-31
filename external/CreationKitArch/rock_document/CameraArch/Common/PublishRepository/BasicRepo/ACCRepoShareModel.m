//
//  ACCRepoShareModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/10/25.
//

#import "ACCRepoShareModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoShare) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoShare)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoShareModel.class];
}

- (ACCRepoShareModel *)repoShare
{
    ACCRepoShareModel *shareModel = [self extensionModelOfClass:ACCRepoShareModel.class];
    NSAssert(shareModel, @"extension model should not be nil");
    return shareModel;
}

@end

@implementation ACCRepoShareModel

#pragma mark - public

- (ACCPublishShareModel *)shareModel
{
    if (!_shareModel) {
        _shareModel = [[ACCPublishShareModel alloc] init];
    }
    return _shareModel;
}

#pragma mark - copying

- (id)copyWithZone:(NSZone *)zone {
    ACCRepoShareModel *model = [[[self class] alloc] init];
    
    model.thirdAppKey = self.thirdAppKey;
    model.shareModel = self.shareModel;

    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol - Optional

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}
@end
