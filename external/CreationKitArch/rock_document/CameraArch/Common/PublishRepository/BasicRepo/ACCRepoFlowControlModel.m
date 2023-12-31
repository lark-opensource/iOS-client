//
//  ACCRepoFlowControlModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/25.
//

#import "ACCRepoFlowControlModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRecordMode.h>
#import "ACCRepoReshootModel.h"

@interface AWEVideoPublishViewModel (RepoFlowControl) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoFlowControl)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoFlowControlModel.class];
}

- (ACCRepoFlowControlModel *)repoFlowControl
{
    ACCRepoFlowControlModel *flowControlModel = [self extensionModelOfClass:ACCRepoFlowControlModel.class];
    NSAssert(flowControlModel, @"extension model should not be nil");
    return flowControlModel;
}

@end

@interface ACCRepoFlowControlModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation ACCRepoFlowControlModel
@synthesize repository;
@synthesize hasRecoveredAudioFragments = _hasRecoveredAudioFragments;

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoFlowControlModel *model = [[[self class] alloc] init];
    model.step = self.step;
    model.disableBackToTabBar = self.disableBackToTabBar;
    model.hasRecoveredAudioFragments = self.hasRecoveredAudioFragments;
    model.videoRecordButtonType = self.videoRecordButtonType;
    model.exclusiveRecordType = self.exclusiveRecordType;
    model.showOneTabExclusively = self.showOneTabExclusively;
    return model;
}

- (NSInteger)exclusiveRecordModeId
{
    if ([self.exclusiveRecordType isEqualToString:@"live"]) {
        return ACCRecordModeLive;
    }
    return 0;
}

- (BOOL)isFixedDuration
{
    ACCRepoDuetModel *duet = [self.repository extensionModelOfClass:ACCRepoDuetModel.class];
    ACCRepoReshootModel *reshoot = [self.repository extensionModelOfClass:ACCRepoReshootModel.class];
    NSAssert((duet != nil) && (reshoot != nil), @"dependency repo model should not be nil");
    if (duet.isDuet) {
        return NO;
    }
    if (reshoot.isReshoot) {
        return YES;
    }
    return NO;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    return @{};
}

@end
