//
//  ACCFilterServiceImpl.h
//  Pods
//
//  Created by DING Leo on 2020/2/6.
//

#import <Foundation/Foundation.h>
#import <CreativeKit/ACCViewModel.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/ACCRecordFilterDefines.h>
#import <CreationKitArch/AWEColorFilterConfigurationHelper.h>
#import <CreationKitComponents/ACCFilterPrivateService.h>

#import <EffectPlatformSDK/EffectPlatform.h>
#import <TTVideoEditor/VERecorder.h>
#import <CreationKitComponents/AWECameraFilterConfiguration.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/AWEColorFilterDataManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCFilterServiceImpl : ACCRecorderViewModel <ACCFilterPrivateService>

@end

NS_ASSUME_NONNULL_END
