//
//  ACCRepoCanvasBusinessModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/5/6.
//

#import "ACCRepoCanvasBusinessModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoCanvasBusiness) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoCanvasBusiness)

- (id)extensionModelForRepositoryWhenSetup
{
    ACCRepoCanvasBusinessModel *model = [[ACCRepoCanvasBusinessModel alloc] init];
    return model;
}

- (ACCRepoCanvasBusinessModel *)repoCanvasBusiness
{
    ACCRepoCanvasBusinessModel *canvasBusinessModel = [self extensionModelOfClass:[ACCRepoCanvasBusinessModel class]];
    NSAssert(canvasBusinessModel, @"extension model should not be nil");
    return canvasBusinessModel;
}

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:[ACCRepoCanvasBusinessModel class]];
}

@end

@interface ACCRepoCanvasBusinessModel() <ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@end

@implementation ACCRepoCanvasBusinessModel

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoCanvasBusinessModel *model = [[ACCRepoCanvasBusinessModel alloc] init];
    model.rePostMusicModel = [self.rePostMusicModel copy];
    model.musicID = self.musicID;
    model.socialType = self.socialType;

    return model;
}

- (void)setRePostMusicModel:(id<ACCMusicModelProtocol>)rePostMusicModel
{
    _rePostMusicModel = rePostMusicModel;
    if (rePostMusicModel != nil && ![rePostMusicModel isOffLine]) {
        self.musicID = rePostMusicModel.musicID;
    }
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return nil;
}

@end
