//
//  ACCRepoRecorderTrackerToolModel.m
//  AWEStudio
//
//  Created by haoyipeng on 2020/10/29.
//

#import "ACCRepoRecorderTrackerToolModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreativeKit/ACCFeatureComponent.h>

@interface AWEVideoPublishViewModel (RepoRecorderTrackerTool)

@end

@implementation AWEVideoPublishViewModel (RepoRecorderTrackerTool)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoRecorderTrackerToolModel.class];
    return info;
}

- (ACCRepoRecorderTrackerToolModel *)repoRecorderTrackerTool
{
    ACCRepoRecorderTrackerToolModel *recordTrackerModel = [self extensionModelOfClass:ACCRepoRecorderTrackerToolModel.class];
    NSAssert(recordTrackerModel, @"extension model should not be nil");
    return recordTrackerModel;
}

@end

@interface ACCRepoRecorderTrackerToolModel ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary *> *componentTimeDic;

@end

@implementation ACCRepoRecorderTrackerToolModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _componentTimeDic = [NSMutableDictionary new];
    }
    return self;
}

- (NSDictionary *)trackerDic
{
    NSMutableDictionary *params = @{}.mutableCopy;
    [params addEntriesFromDictionary:self.componentTimeDic ? @{@"component":self.componentTimeDic}: @{}];
    params[@"music_download_duration"] = @(self.musicDownloadDuration);
    params[@"effect_download_duration"] = @(self.effectDownloadDuration);
    params[@"video_download_duration"] = @(self.videoDownloadDuration);
    params[@"has_music"] = @(self.musicID.length > 0 ? YES : NO);
    params[@"has_sticker"] = @(self.stickerID.length > 0 ? YES : NO);
    params[@"has_authority"] = @(self.hasAuthority);
    return [params copy];
}

#pragma mark - ACCComponentLogDelegate

- (void)logComponent:(id<ACCFeatureComponent>)component selector:(SEL)aSelector duration:(NSTimeInterval)duration
{
    if (component) {
        NSString *componentKey = NSStringFromClass([component class]);
        NSMutableDictionary *valueDic = self.componentTimeDic[componentKey];
        if (!valueDic) {
            valueDic = [NSMutableDictionary new];
            self.componentTimeDic[componentKey] = valueDic;
        }
        NSString *valueKey = NSStringFromSelector(aSelector);
        if (valueKey && !valueDic[valueKey]) {
            valueDic[valueKey] = @(duration);
        }
    }
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
