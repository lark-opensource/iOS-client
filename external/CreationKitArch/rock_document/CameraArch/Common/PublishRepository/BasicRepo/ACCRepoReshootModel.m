//
//  ACCRepoReshootModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/22.
//

#import "ACCRepoReshootModel.h"
#import "ACCVideoDataProtocol.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "ACCRepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoDraftModel.h>

@interface AWEVideoPublishViewModel (RepoShoot) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoShoot)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoReshootModel.class];
    return info;
}

- (ACCRepoReshootModel *)repoReshoot
{
    ACCRepoReshootModel *reshootModel = [self extensionModelOfClass:ACCRepoReshootModel.class];
    NSAssert(reshootModel, @"extension model should not be nil");
    return reshootModel;
}

@end

@interface ACCRepoReshootModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

@end

@implementation ACCRepoReshootModel

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoReshootModel *model = [[[self class] alloc] init];
    model.recordVideoClipRange = self.recordVideoClipRange;
    
    if (self.fullRangeFragmentInfo) { // deep copy full fullRangeFragmentInfo
        NSMutableArray *array = [NSMutableArray array];
        for (id<ACCVideoFragmentInfoProtocol> obj in self.fullRangeFragmentInfo) {
            [array addObject:[(NSObject *)obj copy]];
        }
        model.fullRangeFragmentInfo = array;
    }
    return model;
}

- (BOOL)hasVideoClipEdits
{
    ASSERT_IN_SUB_CLASS
    return NO;
}

- (NSUInteger)getStickerSavePhotoCount
{
    __block NSUInteger totalCount = 0;
    [self.fullRangeFragmentInfo enumerateObjectsUsingBlock:^(id<ACCVideoFragmentInfoProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        totalCount += obj.stickerSavePhotoInfo.photoNames.count;
    }];
    return totalCount;
}

- (void)removeVideoClipEdits
{
    self.recordVideoClipRange = nil;
    if (self.fullRangeFragmentInfo) {
        [self p_removeReshootStickerSavePhotos];
        self.repoVideoInfo.fragmentInfo = self.fullRangeFragmentInfo.mutableCopy;
        self.fullRangeFragmentInfo = nil;
    }
    
    [self.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(id<ACCVideoFragmentInfoProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.clipRange = nil;
    }];
    id<ACCVideoDataProtocol> videoData = [self.repository extensionModelOfProtocol:@protocol(ACCVideoDataProtocol)];
    [videoData resetVideoTimeClipInfo];
}

- (void)p_removeReshootStickerSavePhotos
{
    [self.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(id<ACCVideoFragmentInfoProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isReshoot) {
            ACCRepoDraftModel *repoDraft = [self.repository extensionModelOfClass:ACCRepoDraftModel.class];
            [obj deleteStickerSavePhotos:repoDraft.taskID];
        }
    }];
}

- (ACCRepoVideoInfoModel *)repoVideoInfo
{
    ACCRepoVideoInfoModel *repoVideoInfo = [self.repository extensionModelOfClass:ACCRepoVideoInfoModel.class];
    return repoVideoInfo;
}

#pragma mark - ACCRepositoryCoding

- (void)encodeWithCoder:(nonnull NSCoder *)coder
{
    
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)coder
{
    if (self = [super init]) {
        
    }
    return self;
}

- (id)copyInstanceForSessionCoding:(AWEVideoPublishViewModel *)sessionModel backup:(BOOL)backup
{
    return nil;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{
        @"is_trimmed" : @([self hasVideoClipEdits] ? 1 : 0),
    };
}

#pragma mark - ACCRepositoryContextProtocol

@synthesize repository;

@end
