//
//  MVPRecordCloseComponent.h
//  CameraClient
//
//  Created by Howie He on 2021/6/6.
//  Copyright © 2021 chengfei xiao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCFeatureComponent.h>
#import <CreativeKit/ACCFeatureComponentPlugin.h>
#import <CreativeKit/ACCServiceBindable.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitRTProtocol/ACCCameraControlEvent.h>
#import <CameraClient/ACCRecorderEvent.h>

typedef NS_ENUM(NSInteger, AWESubtitleActionSheetButtonType) {
    AWESubtitleActionSheetButtonNormal,
    AWESubtitleActionSheetButtonHighlight,
    AWESubtitleActionSheetButtonSubtitle
};

NS_ASSUME_NONNULL_BEGIN

@class ACCAnimatedButton;

@interface MVPRecordCloseComponent : ACCFeatureComponent

@property (nonatomic, strong, readonly) ACCAnimatedButton *closeButton;

/**
 * @brief Text to be displayed on the reshoot button. If nil,  `重新拍摄` will be used.
 */
@property (nonatomic, copy, nullable) NSString *reshootTitle;

/**
 * @brief Text to be displayed on the exit button. If nil,  `退出` will be used on the alert style action sheet whilst `退出相机` will be on the quick story style action sheet.
 */
@property (nonatomic, copy, nullable) NSString *exitTitle;

@end

NS_ASSUME_NONNULL_END

@interface LarkRecordSwitchModePlugin : NSObject <ACCFeatureComponentPlugin, ACCServiceBindable, ACCRecordSwitchModeServiceSubscriber>
@end

@interface LarkCameraServicePlugin : NSObject <ACCFeatureComponentPlugin, ACCServiceBindable, ACCCameraControlEvent, ACCRecorderEvent>
@property(nonatomic, assign) NSTimeInterval lastExposureDate;
@end

@interface LarkRecordDeletePlugin : NSObject <ACCFeatureComponentPlugin, ACCServiceBindable>
@end

@interface LarkRecordCompletePlugin : NSObject <ACCFeatureComponentPlugin, ACCServiceBindable>
@end

@interface LarkFilterPlugin : NSObject <ACCFeatureComponentPlugin, ACCServiceBindable>
@end

@interface LarkBeautyFeaturePlugin : NSObject <ACCFeatureComponentPlugin, ACCServiceBindable>
@property(nonatomic, assign) NSInteger callbackTimes;
@end
