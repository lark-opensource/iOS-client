//
//  MODStudioLiteRedPacket.m
//  CameraClient
//
//  Created by haoyipeng on 2022/1/10.
//  Copyright © 2022 chengfei xiao. All rights reserved.
//

#import "MODStudioLiteRedPacket.h"
#import <HTSServiceKit/HTSCompileTimeAdapterManager.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@implementation MODStudioLiteRedPacket
- (nullable NSDictionary *)enterVideoEditPageParams:(AWEVideoPublishViewModel *)publishModel {
    return @{};
}

- (BOOL)isLiteRedPacketRecord:(AWEVideoPublishViewModel *)publishModel {
    return NO;
}

- (BOOL)isLiteRedPacketShootWay:(AWEVideoPublishViewModel *)publishModel {
    return NO;
}

- (BOOL)isLiteRedPacketVideo:(AWEVideoPublishViewModel *)publishModel {
    return NO;
}

- (BOOL)liteAllowCompleteWithPublishModel:(AWEVideoPublishViewModel *)publishModel cameraService:(id<ACCCameraService>)cameraService modeService:(id<ACCRecordSwitchModeService>)modeService {
    return YES;
}

- (nullable NSDictionary *)quailtiyGuideTrackParams:(AWEVideoPublishViewModel *)publishModel {
    return @{};
}

- (NSString *)recordPropType:(AWEVideoPublishViewModel *)publishModel {
    return @"";
}

- (BOOL)stickerIsLiteRedPacket:(AWEVideoPublishViewModel *)publishModel {
    return NO;
}

@end
