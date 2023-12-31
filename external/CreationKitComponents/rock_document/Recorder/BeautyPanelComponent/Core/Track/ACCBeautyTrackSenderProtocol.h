//
//  ACCBeautyTrackSenderProtocol.h
//  CameraClient
//
//  Created by xaingpeng on 2021/3/15.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@protocol ACCBeautyTrackSenderProtocol <NSObject>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, strong, readonly) RACSignal<NSNumber *> *beautySwitchButtonClickedSignal;
@property (nonatomic, strong, readonly) RACSignal *modernBeautyButtonClickedSignal;
@property (nonatomic, strong, readonly) RACSignal *flowServiceDidCompleteRecordSignal;
@property (nonatomic, strong, readonly) RACSignal<RACTwoTuple<NSNumber *, NSNumber *> *> *composerBeautyViewControllerDidSwitchSignal;

@end

NS_ASSUME_NONNULL_END
