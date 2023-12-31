//
//  ACCRecordARServiceImpl.h
//  CameraClient
//
//  Created by chengfei xiao on 2020/4/7.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/VERecorder.h>
#import <TTVideoEditor/IESMMEffectMessage.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import "AWEVideoRecorderARGestureDelegateModel.h"
#import "ACCRecordARService.h"

NS_ASSUME_NONNULL_BEGIN


@protocol ACCRecordARProvideProtocol <NSObject>
@property (nonatomic, strong) AWEVideoRecorderARGestureDelegateModel *arGesturesDelegate;
@property (nonatomic, strong, readonly) RACSignal<ACCInputTextChangetPack> *inputTextChangeSignal;
@property (nonatomic, strong, readonly) RACSignal *inputCompleteSignal;
@end


@interface ACCRecordARServiceImpl : NSObject <ACCRecordARProvideProtocol, ACCRecordARService>
@property (nonatomic, strong, readonly) RACSignal *showARInputSignal;
@property (nonatomic, strong, readonly) RACSignal *dismissARInputSignal;

- (void)sendSignalWhenInputTextChanged:(NSString *)text message:(IESMMEffectMessage *)messageModel;
- (void)sendSignalWhenInputComplete:(BOOL)confirmTextInput;

@end

NS_ASSUME_NONNULL_END
