//
//  ACCStudioLiteRedPacketProtocol.h
//  CameraClient
//
//  Created by Fengfanhua.byte on 2021/11/18.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

@class AWEVideoPublishViewModel;
@protocol ACCCameraService;
@protocol ACCRecordSwitchModeService;

@protocol ACCStudioLiteRedPacket <NSObject>

- (BOOL)isLiteRedPacketRecord:(AWEVideoPublishViewModel *)publishModel;
- (BOOL)isLiteRedPacketShootWay:(AWEVideoPublishViewModel *)publishModel;


- (NSString *)recordPropType:(AWEVideoPublishViewModel *)publishModel;

// 拍摄后的视频是否是红包视频
- (BOOL)isLiteRedPacketVideo:(AWEVideoPublishViewModel *)publishModel;

// 道具是否是红包道具
- (BOOL)stickerIsLiteRedPacket:(AWEVideoPublishViewModel *)publishModel;

// 游戏道具是否可以手动结束
- (BOOL)liteAllowCompleteWithPublishModel:(AWEVideoPublishViewModel *)publishModel cameraService:(id<ACCCameraService>)cameraService modeService:(id<ACCRecordSwitchModeService>)modeService;


- (nullable NSDictionary *)enterVideoEditPageParams:(AWEVideoPublishViewModel *)publishModel;
- (nullable NSDictionary *)quailtiyGuideTrackParams:(AWEVideoPublishViewModel *)publishModel;

@end

FOUNDATION_STATIC_INLINE id<ACCStudioLiteRedPacket> ACCStudioLiteRedPacket() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCStudioLiteRedPacket)];
}
