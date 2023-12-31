//
//  ACCRepoMVModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import "ACCRepoMVModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

@interface AWEVideoPublishViewModel (RepoMV) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoMV)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoMVModel.class];
    return info;
}

- (ACCRepoMVModel *)repoMV
{
    ACCRepoMVModel *mvModel = [self extensionModelOfClass:ACCRepoMVModel.class];
    NSAssert(mvModel, @"extension model should not be nil");
    return mvModel;
}

@end

@interface ACCRepoMVModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation ACCRepoMVModel

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoMVModel *model = [[[self class] alloc] init];
    model.mvTemplateType = self.mvTemplateType;
    model.templateModelId = self.templateModelId;
    model.templateModelTip = self.templateModelTip;
    model.templateMaxMaterial = self.templateMaxMaterial;
    model.templateMinMaterial = self.templateMinMaterial;
    model.templateMusicId = self.templateMusicId;
    model.templateMusicFileName = self.templateMusicFileName;
    model.templateMaterials = self.templateMaterials;
    model.mvChallengeName = self.mvChallengeName;
    
    model.mvMusic = self.mvMusic;
    model.enableOriginSoundInMV = self.enableOriginSoundInMV;
    model.slideshowMVID = self.slideshowMVID;
    model.serverExecutedImageDict = self.serverExecutedImageDict;
    return model;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    
    return @{};
}

@end
