//
//  ACCFilterTrackerSender.h
//  CameraClient
//
//  Created by haoyipeng on 2021/3/5.
//

#import <Foundation/Foundation.h>
#import "ACCFilterTrackSenderProtocol.h"
#import <CreationKitInfra/ACCTrackerSender.h>
#import <CreationKitInfra/ACCRACWrapper.h>
@class AWEVideoPublishViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface ACCFilterTrackerSender : ACCTrackerSender <ACCFilterTrackSenderProtocol>

@property (nonatomic, copy) AWEVideoPublishViewModel *(^getPublishModelBlock)(void);

- (void)sendFilterViewWillShowSignal;
- (void)sendFilterViewWillDisappearSignalWithFilter:(IESEffectModel *)filter;
- (void)sendFilterSlideSwitchCompleteSignal:(IESEffectModel *)filter;
- (void)sendFilterSlideSwitchStartSignal;
- (void)sendFilterViewDidClickCategorySignal:(IESCategoryModel *)category;
- (void)sendFilterViewDidClickFilterSignal:(IESEffectModel *)filter;

@end

NS_ASSUME_NONNULL_END
