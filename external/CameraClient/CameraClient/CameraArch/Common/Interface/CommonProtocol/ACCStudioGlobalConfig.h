//
//  ACCStudioGlobalConfig.h
//  CameraClient
//
//  Created by Lincoln on 2021/6/24.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCServiceLocator.h>

@class ACCRecordViewControllerInputData;
@class AWEStickerCategoryModel;
@class AWEVideoPublishViewModel;
@class IESEffectModel;
@protocol AWEStickerPickerControllerPluginProtocol;
@protocol ACCCameraService;
@protocol ACCRecordSwitchModeService;

NS_ASSUME_NONNULL_BEGIN

@protocol ACCStudioGlobalConfig <NSObject>

- (BOOL)shouldKeepLiveMode;

+ (BOOL)isLite;

+ (BOOL)supportEditWithPublish;
- (BOOL)supportEditWithPublish;

@end

FOUNDATION_STATIC_INLINE id<ACCStudioGlobalConfig> ACCStudioGlobalConfig() {
    return [ACCBaseServiceProvider() resolveObject:@protocol(ACCStudioGlobalConfig)];
}

NS_ASSUME_NONNULL_END
