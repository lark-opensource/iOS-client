//
//  ACCFilterTrackSenderProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2021/3/8.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@class IESCategoryModel;
@class AWEVideoPublishViewModel;
@protocol ACCFilterTrackSenderProtocol <NSObject>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, strong, readonly) RACSignal *filterViewWillShowSignal;
// currentFilter
@property (nonatomic, strong, readonly) RACSignal<IESEffectModel *> *filterViewWillDisappearSignal;
// switch to filter
@property (nonatomic, strong, readonly) RACSignal<IESEffectModel *> *filterSlideSwitchCompleteSignal;
@property (nonatomic, strong, readonly) RACSignal *filterSlideSwitchStartSignal;
// manually click category or filter
@property (nonatomic, strong, readonly) RACSignal<IESCategoryModel *> *filterViewDidClickCategorySignal;
@property (nonatomic, strong, readonly) RACSignal<IESEffectModel *> *filterViewDidClickFilterSignal;

@end

NS_ASSUME_NONNULL_END
