//
//  AWERepoReshootModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import "AWERepoReshootModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "AWERepoVideoInfoModel.h"

@interface AWEVideoPublishViewModel (RepoShoot) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoShoot)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoReshootModel.class];
	return info;
}

- (AWERepoReshootModel *)repoReshoot
{
    AWERepoReshootModel *reshootModel = [self extensionModelOfClass:AWERepoReshootModel.class];
    NSAssert(reshootModel, @"extension model should not be nil");
    return reshootModel;
}

@end

@interface AWERepoReshootModel()<ACCRepositoryContextProtocol>

@end

@implementation AWERepoReshootModel

@synthesize repository = _repository;

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoReshootModel *model = [super copyWithZone:zone];
    
    model.isReshoot = self.isReshoot;
    model.fromCreateId = self.fromCreateId;
    model.fromTaskId = self.fromTaskId;
    model.recordVideoClipRange = self.recordVideoClipRange;
    model.durationAfterReshoot = self.durationAfterReshoot;
    model.durationBeforeReshoot = self.durationBeforeReshoot;
    return model;
}

- (BOOL)hasVideoClipEdits
{
    __block BOOL hasClip = NO;
    AWERepoVideoInfoModel *videoRepo = [self.repository extensionModelOfClass:AWERepoVideoInfoModel.class];
    
    [videoRepo.video.videoTimeClipInfo enumerateKeysAndObjectsUsingBlock:^(AVAsset * _Nonnull key, IESMMVideoDataClipRange * _Nonnull obj, BOOL * _Nonnull stop) {
        
        BOOL isPlaceHolderAsset = NO;
        if ([key isKindOfClass:[AVURLAsset class]]) {
            NSURL *url = [(AVURLAsset *)key URL];
            isPlaceHolderAsset = [url.absoluteString hasSuffix:@"blankown2.mp4"];
        }
        if ((obj.durationSeconds <= CMTimeGetSeconds(key.duration) - 0.0001) && !isPlaceHolderAsset) {
            *stop = YES;
            hasClip = YES;
        }
    }];
    
    return hasClip;
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
    [coder encodeObject:self.recordVideoClipRangeJson forKey:@"recordVideoClipRangeJson"];
    [coder encodeObject:self.fullRangeFragmentInfoJson forKey:@"fullRangeFragmentInfoJson"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    if (self = [super init]) {
        self.recordVideoClipRangeJson = [coder decodeObjectForKey:@"recordVideoClipRangeJson"];
        self.fullRangeFragmentInfoJson = [coder decodeObjectForKey:@"fullRangeFragmentInfoJson"];
    }
    return self;
}

@end
