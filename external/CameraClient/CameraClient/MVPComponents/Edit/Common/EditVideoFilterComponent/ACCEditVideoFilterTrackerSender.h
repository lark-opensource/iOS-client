//
//  ACCEditVideoFilterTrackerSender.h
//  CameraClient
//
//  Created by xiangpeng on 2021/3/15.
//

#import "ACCEditVideoFilterTrackSenderProtocol.h"
#import <EffectPlatformSDK/IESEffectModel.h>

#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/ACCTrackerSender.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditVideoFilterTrackerSender : ACCTrackerSender <ACCEditVideoFilterTrackSenderProtocol>

- (void)sendFilterClickedSignal;
- (void)sendFilterSwitchManagerCompleteSignalWithFilter:(IESEffectModel *)filter;
- (void)sendTabFilterControllerWillDismissSignalWithSelectedFilter:(IESEffectModel *)filter;



@end

NS_ASSUME_NONNULL_END
