//
//  ACCRepoBeautyModel.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/21.
//

#import "ACCRepoBeautyModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoBeauty) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoBeauty)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoBeautyModel.class];
    return info;
}

- (ACCRepoBeautyModel *)repoBeauty
{
    ACCRepoBeautyModel *beautyModel = [self extensionModelOfClass:ACCRepoBeautyModel.class];
    NSAssert(beautyModel, @"extension model should not be nil");
    return beautyModel;
}

@end

@interface ACCRepoBeautyModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation ACCRepoBeautyModel

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoBeautyModel *model = [[[self class] alloc] init];
    model.lastSelectBeautyCategoryId = self.lastSelectBeautyCategoryId;
    model.selectedBeautyDic = self.selectedBeautyDic;
    model.beautyValueDic = self.beautyValueDic;
    model.selectedAlbumDic = self.selectedAlbumDic;
    model.gender = self.gender;
    model.appliedEffectIds = self.appliedEffectIds;
    return model;
}


- (BOOL)hadUseBeauty
{
    return self.beautyValueDic.count > 0;
}

- (BOOL)isEqualToObject:(ACCRepoBeautyModel *)object
{
    if (![object isKindOfClass:[ACCRepoBeautyModel class]]) {
        return NO;
    }

#define CHECK_PROPERTY(container) \
if (self.container.count != object.container.count) { \
    return NO; \
} \
if (self.container && object.container) { \
    if (![self.container isEqual:object.container]) { \
        return NO; \
    } \
}

    CHECK_PROPERTY(selectedBeautyDic);
    CHECK_PROPERTY(beautyValueDic);
    CHECK_PROPERTY(selectedAlbumDic);
    CHECK_PROPERTY(appliedEffectIds);

#undef CHECK_PROPERTY

    return YES;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    return @{};
}

@end
