//
//  ACCBeautyTrackerSender.h
//  CameraClient
//
//  Created by xiangpeng on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import "ACCBeautyTrackSenderProtocol.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/ACCTrackerSender.h>
@class AWEVideoPublishViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCBeautyTrackerSender : ACCTrackerSender <ACCBeautyTrackSenderProtocol>

@property (nonatomic, copy) AWEVideoPublishViewModel *(^getPublishModelBlock)(void);

- (void)sendBeautySwitchButtonClickedSignal:(BOOL)isOn;
- (void)sendModernBeautyButtonClickedSignal;
- (void)sendFlowServiceDidCompleteRecordSignal;
- (void)sendComposerBeautyViewControllerDidSwitchSignal:(BOOL)isOn isManually:(BOOL)isManually;

@end

NS_ASSUME_NONNULL_END
