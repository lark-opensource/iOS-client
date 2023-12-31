//
//  ACCRecordCompleteTrackSenderProtocol.h
//  CameraClient
//
//  Created by haoyipeng on 2022/2/17.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

typedef NS_ENUM(NSUInteger, ACCRecordDeleteActionType) {
    ACCRecordDeleteActionTypeCancel,
    ACCRecordDeleteActionTypeConfirm,
};


@protocol ACCRecordDeleteTrackSenderProtocol <NSObject>

@property (nonatomic, strong, readonly, nonnull) RACSignal *deleteButtonDidClickedSignal;
@property (nonatomic, strong, readonly, nonnull) RACSignal *deleteConfirmAlertShowSignal;
@property (nonatomic, strong, readonly, nonnull) RACSignal<NSNumber *> *deleteConfirmAlertActionSignal;


@end
