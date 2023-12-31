//
//  ACCCameraSwapService.h
//
//  Created by zhuoeijin on 2021/12/1.
//

#ifndef ACCCameraSwapService_h
#define ACCCameraSwapService_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/// CameraSwapService is a Biz Service, in order to capsule all the camera swap calling.

typedef NS_ENUM(NSUInteger, ACCCameraSwapSource) {
    ACCCameraSwapSourceUnknown, /// 未知来源
    ACCCameraSwapSourceToolBarItem, /// 侧边栏icon点击
    ACCCameraSwapSourcePropPanel, /// 道具面板展开后，右上角的icon
    ACCCameraSwapSourceProp, /// 道具默认前置
    ACCCameraSwapSourceDoubleTap, /// 双击手势切换
    ACCCameraSwapSourceMale /// 男性默认后置
};

@protocol ACCCameraSwapService <NSObject>

@property (nonatomic, assign, readonly) BOOL isUserSwappedCamera;
@property (nonatomic, assign, readonly) AVCaptureDevicePosition currentCameraPosition;

- (void)switchToCameraPosition:(AVCaptureDevicePosition)position source:(ACCCameraSwapSource)source;
- (void)switchToOppositeCameraPositionWithSource:(ACCCameraSwapSource)source;
- (void)syncCameraActualPosition;

@end


#endif /* ACCCameraSwapService_h */
