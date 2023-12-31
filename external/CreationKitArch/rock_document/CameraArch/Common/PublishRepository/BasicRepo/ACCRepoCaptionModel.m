//
//  ACCRepoCaptionModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import "ACCRepoCaptionModel.h"
#import <CreationKitArch/AWEStudioCaptionModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface AWEVideoPublishViewModel (RepoCaption) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoCaption)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoCaptionModel.class];
}

- (ACCRepoCaptionModel *)repoCaption
{
    ACCRepoCaptionModel *captionModel = [self extensionModelOfClass:ACCRepoCaptionModel.class];
    NSAssert(captionModel, @"extension model should not be nil");
    return captionModel;
}

@end

@interface ACCRepoCaptionModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation ACCRepoCaptionModel
@synthesize repository;

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoCaptionModel *model = [[[self class] alloc] init];
    model.mixAudioUrl = self.mixAudioUrl;
    model.mixAudioInfoMd5 = self.mixAudioInfoMd5;
    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    return @{};
}

#pragma mark - Public

- (BOOL)audioDidChanged
{
    return ![self.mixAudioInfoMd5 isEqualToString:self.currentMixAudioInfoMd5];
}

- (void)resetAudioChangeFlag
{
    NSAssert(NO, @"should implementation in sub class");
}

- (NSString *)currentMixAudioInfoMd5
{
    NSAssert(NO, @"should implementation in sub class");
    return @"";
}

@end
