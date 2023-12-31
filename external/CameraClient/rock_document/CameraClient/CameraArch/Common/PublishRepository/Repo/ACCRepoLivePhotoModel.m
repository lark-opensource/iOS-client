//
//  ACCRepoLivePhotoModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/7/15.
//

#import "ACCRepoLivePhotoModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "AWERepoPublishConfigModel.h"

@interface AWEVideoPublishViewModel (RepoLivePhoto) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoLivePhoto)

- (id)extensionModelForRepositoryWhenSetup
{
    ACCRepoLivePhotoModel *model = [[ACCRepoLivePhotoModel alloc] init];
    return model;
}

- (ACCRepoLivePhotoModel *)repoLivePhoto
{
    ACCRepoLivePhotoModel *livePhotoModel = [self extensionModelOfClass:[ACCRepoLivePhotoModel class]];
    NSAssert(livePhotoModel, @"extension model should not be nil");
    return livePhotoModel;
}

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:[ACCRepoLivePhotoModel class]];
}

@end

@interface ACCRepoLivePhotoModel() <ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@end

@implementation ACCRepoLivePhotoModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self reset];
    }
    return self;
}

- (void)reset
{
    _businessType       = ACCLivePhotoTypeNone;
    _imagePathList      = nil;
    _durationPerFrame   = 0.1;
    _repeatCount        = 5;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoLivePhotoModel *model = [[ACCRepoLivePhotoModel alloc] init];
    
    model.businessType = self.businessType;
    model.imagePathList = self.imagePathList;
    model.durationPerFrame = self.durationPerFrame;
    model.repeatCount = self.repeatCount;

    return model;
}

- (NSTimeInterval)videoPlayDuration
{
    NSTimeInterval duration = 1.0;
    switch (self.businessType) {
        case ACCLivePhotoTypeNone: {
            NSAssert(NO, @"invalid type");
            break;
        }
        case ACCLivePhotoTypeBoomerang: {
            NSTimeInterval part = self.durationPerFrame * self.imagePathList.count * 2;
            duration = part * self.repeatCount;
            break;
        }
        case ACCLivePhotoTypePlainRepeat: {
            NSTimeInterval part = self.durationPerFrame * self.imagePathList.count;
            duration = part * self.repeatCount;
            break;
        }
    }
    return duration;
}

- (void)updateRepeatCountWithVideoPlayDuration:(NSTimeInterval)videoDuration
{
    // 这里会有除不尽的情况，比如Boomerang录制时长是2s，视频时长10s，
    // 跟PM沟通后，视频时长需实际配置为可整除的值
    CGFloat repeatCount = 1.0;
    NSTimeInterval recordDuration = (double)self.durationPerFrame * (double)self.imagePathList.count;
    switch (self.businessType) {
        case ACCLivePhotoTypeNone:
            NSAssert(NO, @"invalid type");
            break;
        case ACCLivePhotoTypeBoomerang:
            repeatCount = round(videoDuration / (recordDuration * 2.0));
            break;
        case ACCLivePhotoTypePlainRepeat:
            repeatCount = round(videoDuration / recordDuration);
            break;
    }
    self.repeatCount = repeatCount;
}

+ (CGFloat)repeatCountWithBizType:(ACCLivePhotoType)bizType
                   recordDuration:(NSTimeInterval)recordDuration
                    videoDuration:(NSTimeInterval)videoDuration
{
    // 这里会有除不尽的情况，比如录制时长是2s，视频时长10s，
    // 跟PM沟通后，视频时长需实际配置为可整除的值
    CGFloat repeatCount = 1.0;
    switch (bizType) {
        case ACCLivePhotoTypeNone:
            NSAssert(NO, @"invalid type");
            break;
        case ACCLivePhotoTypeBoomerang:
            repeatCount = round(videoDuration / (recordDuration * 2.0));
            break;
        case ACCLivePhotoTypePlainRepeat:
            repeatCount = round(videoDuration / recordDuration);
            break;
    }
    return repeatCount;
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    if (self.businessType != ACCLivePhotoTypeNone) {
        publishViewModel.repoPublishConfig.categoryDA = ACCFeedTypeExtraCategoryLivePhoto;
    }
    return params;
}

@end
