//
//  ACCRepoCanvasModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/6.
//

#import "ACCRepoCanvasModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoCanvas) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoCanvas)

- (id)extensionModelForRepositoryWhenSetup
{
    ACCRepoCanvasModel *model = [[ACCRepoCanvasModel alloc] init];
    return model;
}

- (ACCRepoCanvasModel *)repoCanvas
{
    ACCRepoCanvasModel *canvasModel = [self extensionModelOfClass:[ACCRepoCanvasModel class]];
    NSAssert(canvasModel, @"extension model should not be nil");
    return canvasModel;
}

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:[ACCRepoCanvasModel class]];
}

@end

@interface ACCRepoCanvasModel() <ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@end

@implementation ACCRepoCanvasModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _videoDuration = 10;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoCanvasModel *model = [[ACCRepoCanvasModel alloc] init];
    model.videoURL = self.videoURL;
    model.canvasContentType = self.canvasContentType;
    model.source = [self.source copy];
    model.config = [self.config copy];
    model.groupId = self.groupId;
    model.videoDuration = self.videoDuration;
    model.minimumScale = self.minimumScale;
    model.maximumScale = self.maximumScale;

    return model;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return nil;
}

@end
