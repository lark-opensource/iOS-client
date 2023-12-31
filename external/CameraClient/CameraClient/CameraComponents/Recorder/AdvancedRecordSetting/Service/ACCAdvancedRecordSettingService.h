//
//  ACCAdvancedRecordSettingService.h
//  Aweme
//
//  Created by Shichen Peng on 2021/11/2.
//

#ifndef ACCAdvancedRecordSettingService_h
#define ACCAdvancedRecordSettingService_h

#import <Foundation/Foundation.h>

// CreationKitRTProtocol
#import <CreationKitRTProtocol/ACCCameraSubscription.h>

// CameraClient
#import <CameraClient/ACCAdvancedRecordSettingItem.h>
#import <CameraClient/ACCAdvancedRecordSettingComponent.h>

@protocol ACCAdvancedRecordSettingServiceSubScriber, ACCAdvancedRecordSettingService;

@protocol ACCAdvancedRecordSettingServiceSubScriber <NSObject>

@optional

// only used for switcher
- (void)advancedRecordSettingService:(id<ACCAdvancedRecordSettingService>)service configure:(ACCAdvancedRecordSettingType)type switchStatueChangeTo:(BOOL)status needSync:(BOOL)needSync;

// only used for segment UIcontrol
- (void)advancedRecordSettingService:(id<ACCAdvancedRecordSettingService>)service configure:(ACCAdvancedRecordSettingType)type segmentStatueChangeTo:(NSUInteger)index needSync:(BOOL)needSync;

@end

@protocol ACCAdvancedRecordSettingService <NSObject>

@property (nonatomic, weak, nullable) ACCAdvancedRecordSettingComponent *delegate;
@property (nonatomic, strong, nonnull) ACCCameraSubscription *subscription;

- (void)addSubscriber:(id<ACCAdvancedRecordSettingServiceSubScriber>)subscriber;
- (void)removeSubscriber:(id<ACCAdvancedRecordSettingServiceSubScriber>)subscriber;

@end

#endif /* ACCAdvancedRecordSettingService_h */
