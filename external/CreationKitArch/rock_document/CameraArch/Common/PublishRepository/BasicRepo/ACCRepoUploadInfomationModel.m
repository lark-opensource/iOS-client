//
//  ACCRepoUploadInfomationModel.m
//  CameraClient
//
//  Created by haoyipeng on 2020/10/22.
//

#import "ACCRepoUploadInfomationModel.h"

#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/ACCRepoContextModel.h>

@interface AWEVideoPublishViewModel (RepoUploadInfo) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoUploadInfo)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoUploadInfomationModel.class];
    return info;
}

- (ACCRepoUploadInfomationModel *)repoUploadInfo
{
    ACCRepoUploadInfomationModel *uploadInfoModel = [self extensionModelOfClass:ACCRepoUploadInfomationModel.class];
    NSAssert(uploadInfoModel, @"extension model should not be nil");
    return uploadInfoModel;
}

@end

@implementation ACCRepoUploadInfomationModel

- (instancetype)init
{
    if (self = [super init]) {
        _isSpeedChange = NO;
        _videoClipMode = AWEVideoClipModeNormal;
        _extraDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

@synthesize repository;

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoUploadInfomationModel *copy = [[[self class] alloc] init];
    copy.extraDict = [self.extraDict mutableCopy];
    copy.videoClipMode = self.videoClipMode;
    copy.originUploadPhotoCount = self.originUploadPhotoCount;
    copy.originUploadVideoClipCount = self.originUploadVideoClipCount;
    copy.clipSourceType = self.clipSourceType;
    copy.isMultiVideoUpload = self.isMultiVideoUpload;
    copy.mediaSubType = self.mediaSubType;
    copy.isFaceuVideoFirst = self.isFaceuVideoFirst;
    copy.toBeUploadedImage = self.toBeUploadedImage.copy;
    copy.sourceInfos = self.sourceInfos;
    copy.selectedUploadAssets = [self.selectedUploadAssets mutableCopy];
   
    return copy;
}

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}

#pragma mark - Public

- (BOOL)isAIVideoClipMode
{
    return self.videoClipMode == AWEVideoClipModeAI;
}

- (NSArray *)sourceInfosArray
{
    if (self.sourceInfos.count > 0) {
        NSMutableArray *result = [NSMutableArray new];
        for (AWEVideoPublishSourceInfo *info in self.sourceInfos) {
            NSDictionary *item = [info jsonInfo];
            if (item != nil) {
                [result addObject:item];
            }
        }
        return result;
    }
    return nil;
}

#pragma mark - Getter

- (NSMutableDictionary *)extraDict
{
    if (!_extraDict) {
        _extraDict = [NSMutableDictionary dictionary];
    }
    return _extraDict;
}

@end
