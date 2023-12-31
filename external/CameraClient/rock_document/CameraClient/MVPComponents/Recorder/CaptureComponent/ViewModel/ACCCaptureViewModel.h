//
//  ACCCaptureViewModel.h
//  CameraClient
//
//  Created by 郝一鹏 on 2020/5/7.
//

#import "ACCCaptureService.h"
#import <CreationKitArch/ACCRecorderViewModel.h>
NS_ASSUME_NONNULL_BEGIN

@class IESMMEffectMessage, ACCRecordMode;

@interface ACCCaptureViewModel : ACCRecorderViewModel <ACCCaptureService>

@property (nonatomic, copy, nullable) void(^toastHandler)(NSString *text);
@property (nonatomic, copy, nullable) void(^loadingHandler)(BOOL close, NSString * _Nullable text);
@property (nonatomic, copy, nullable) void(^sendMessageHandler)(IESMMEffectMessage * msg);

- (void)handleEFfectMessageWithArg2:(NSInteger)arg2 arg3:(NSString *)arg3;

- (void)send_captureReadyForSwitchModeSignal:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode;

@end

NS_ASSUME_NONNULL_END
