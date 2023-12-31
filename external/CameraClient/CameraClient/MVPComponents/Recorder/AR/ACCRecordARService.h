//
//  ACCRecordARService.h
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2021/1/10.
//

#import <Foundation/Foundation.h>
#import <CreationKitInfra/ACCRACWrapper.h>

NS_ASSUME_NONNULL_BEGIN

typedef RACTwoTuple<NSString *, IESMMEffectMessage *> *ACCInputTextChangetPack;
@class IESMMEffectMessage;

@protocol ACCRecordARService <NSObject>

@property (nonatomic, strong) id<UIGestureRecognizerDelegate> arGesturesDelegate;
@property (nonatomic, strong, readonly) RACSignal<ACCInputTextChangetPack> *inputTextChangeSignal;
@property (nonatomic, strong, readonly) RACSignal *inputCompleteSignal;

- (void)sendSignalARInputShowWithMsg:(IESMMEffectMessage *)msg;
- (void)sendSignalARInputDismiss;

@end

NS_ASSUME_NONNULL_END
