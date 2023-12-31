//
//  ACCEditVideoFilterTrackSenderProtocol.h
//  CameraClient
//
//  Created by xaingpeng on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@protocol ACCEditVideoFilterTrackSenderProtocol <NSObject>

@property (nonatomic, strong, readonly) RACSignal *filterClickedSignal;
@property (nonatomic, strong, readonly) RACSignal<IESEffectModel *> *filterSwitchManagerCompleteSignal;
@property (nonatomic, strong, readonly) RACSignal<IESEffectModel *> *tabFilterControllerWillDismissSignal;

@end

NS_ASSUME_NONNULL_END
