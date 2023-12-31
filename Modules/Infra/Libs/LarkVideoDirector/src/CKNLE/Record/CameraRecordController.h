//
//  CameraRecordController.h
//  LarkVideoDirector
//
//  Created by 李晨 on 2022/1/19.
//

#import <Foundation/Foundation.h>
#import <CameraClient/ACCRecordViewController.h>
#import "LVDCameraService.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraRecordController : ACCRecordViewController<UIGestureRecognizerDelegate>

@property (weak, nonatomic) id<LVDCameraControllerDelegate> delegate;

// 标记是否已经调用过 vc 的 dismiss 方法
@property (assign, nonatomic) BOOL dismissed;

@end

NS_ASSUME_NONNULL_END
