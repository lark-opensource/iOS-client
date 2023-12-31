//
//  AWERepoFlowControlModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/25.
//

#import "AWERepoTrackModel.h"
#import "AWERepoFlowControlModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (AWERepoFlowControl) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoFlowControl)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoFlowControlModel.class];
	return info;
}

- (AWERepoFlowControlModel *)repoFlowControl
{
    AWERepoFlowControlModel *flowControlModel = [self extensionModelOfClass:AWERepoFlowControlModel.class];
    NSAssert(flowControlModel, @"extension model should not be nil");
    return flowControlModel;
}

@end

@interface AWERepoFlowControlModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation AWERepoFlowControlModel

- (id)copyWithZone:(NSZone *)zone
{
    AWERepoFlowControlModel *model = [super copyWithZone:zone];
    model.LVHasRecoverFlag = self.LVHasRecoverFlag;
    model.isShowingHalfScreenAlbum = self.isShowingHalfScreenAlbum;
    model.isSpecialPlusButton = self.isSpecialPlusButton;
    model.enterFromType = self.enterFromType;
    model.modeId = self.modeId;
    return model;
}

- (void)setLVHasRecoverFlag:(ACCLVFrameRecoverOption)LVRecoverFlag
{
    _LVHasRecoverFlag = LVRecoverFlag;
    if (self.LVHasRecoverFlag == ACCLVFrameRecoverAll) {
        self.hasRecoveredAudioFragments = YES;
    }
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    NSMutableDictionary *params = @{}.mutableCopy;
    
    params[@"tab_name"] = publishViewModel.repoTrack.tabName;

    return params;
}

@end
