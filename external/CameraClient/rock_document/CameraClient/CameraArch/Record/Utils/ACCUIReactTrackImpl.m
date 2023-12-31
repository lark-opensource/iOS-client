//
//  ACCToolUIReactTracker.m
//  CameraClient-Pods-AwemeCore
//
//  Created by Leon on 2021/11/2.
//

#import "ACCUIReactTrackImpl.h"
#import <CreativeKit/ACCToolUIReactTracker.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCRepoRecorderTrackerToolModel.h"
#import "ACCKdebugSignPost.h"

#pragma mark - ACCToolUIReactTracker

@interface ACCUIReactTrackImpl()

@property (nonatomic, strong) ACCToolUIReactTracker *tracker;

@end

@implementation ACCUIReactTrackImpl

- (instancetype)init {
    if (self = [super init]) {
        self.tracker = [[ACCToolUIReactTracker alloc] init];
    }
    return self;
}

- (NSString *)latestEventName {
    return self.tracker.latestEventName;
}

- (void)eventBegin:(NSString *)event {
    [self.tracker eventBegin:event withExcuting:^{
        ACCKdebugSignPostStart(101, 0, 0, 0, 0);
    }];
}

- (void)eventEnd:(NSString *)event withPublishModel:(AWEVideoPublishViewModel *)publishModel {
    [self.tracker eventEnd:event withParams:[self getBizParmas:publishModel] excuting:^{
        ACCKdebugSignPostEnd(101, 0, 0, 0, 0);
    }];
}

#pragma mark - Private

- (NSDictionary *)getBizParmas:(AWEVideoPublishViewModel *)publishViewModel {
    if (publishViewModel == nil) return @{};
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    [params addEntriesFromDictionary:publishViewModel.repoTrack.referExtra ? : @{}];
    [params addEntriesFromDictionary:publishViewModel.repoTrack.commonTrackInfoDic ? : @{}];
    [params addEntriesFromDictionary:publishViewModel.repoRecorderTrackerTool.trackerDic ?: @{}];
    return params.copy;
}

@end
