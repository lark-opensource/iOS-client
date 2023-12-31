//
//  ACCRecordViewControllerInputData.m
//  Pods
//
//  Created by songxiangwu on 2019/8/20.
//

#import "ACCRecordViewControllerInputData.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "ACCConfigKeyDefines.h"

#import <CreativeKit/ACCMacros.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

@implementation ACCRecordViewControllerInputData

- (instancetype)init
{
    self = [super init];
    if (self) {
        _firstCaptureAppState = -1;
    }
    return self;
}

//需要解耦 AWEVideoPublishViewModel
// 需要跟config解耦
- (void)setPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    _publishModel = publishModel;
    if (_publishModel.repoDraft.isBackUp || _publishModel.repoDraft.isDraft) {
        [config updateCurrentVideoLenthMode:(ACCRecordLengthMode)_publishModel.repoContext.videoLenthMode];
    } else {
        _publishModel.repoContext.videoLenthMode = (ACCRecordLengthMode)[config currentVideoLenthMode];
    }
    _publishModel.repoTrack.recordRouteNumber = @(1);
}

- (void)setLocalSticker:(IESEffectModel *)localSticker
{
    if (!ACCConfigBool(kConfigBool_enable_multi_seg_prop) && localSticker.isMultiSegProp) {
        return;
    }
    _localSticker = localSticker;
}

- (void)recordCurrentApplicateState
{
    if (self.firstCaptureAppState == -1) {
        self.firstCaptureAppState = [[UIApplication sharedApplication] applicationState];
    }
}

- (nonnull NSString *)createId {
    return self.publishModel.repoContext.createId;
}

@end
