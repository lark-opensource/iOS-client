//
//  AWEStickerPickerControllerSwitchCameraPlugin.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/10/19.
//

#import <Foundation/Foundation.h>
#import "AWEStickerPickerControllerPluginProtocol.h"
#import <CreationKitRTProtocol/ACCCameraService.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESServiceProvider;

/**
 * 前后置摄像头切换插件
 */
@interface AWEStickerPickerControllerSwitchCameraPlugin : NSObject <AWEStickerPickerControllerPluginProtocol>

- (instancetype)initWithServiceProvider:(id<IESServiceProvider>)serviceProvider;

@end

NS_ASSUME_NONNULL_END
