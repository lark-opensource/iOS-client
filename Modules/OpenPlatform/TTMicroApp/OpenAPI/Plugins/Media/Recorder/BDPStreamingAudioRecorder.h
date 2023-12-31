//
//  BDPStreamingAudioRecorder.h
//  TTMicroApp
//
//  Created by houjihu on 2019/8/15.
//

#import <Foundation/Foundation.h>
#import <OPPluginManagerAdapter/BDPJSBridge.h>
#import <OPFoundation/BDPCommon.h>

typedef NS_ENUM(NSInteger, BDPAudioRecorderErrorType) {
    BDPAudioRecorderErrorTypeSuccess = 0,
    BDPAudioRecorderErrorTypeOperationTypeInvalid,
    BDPAudioRecorderErrorTypeStartFail,
    BDPAudioRecorderErrorTypePauseFail,
    BDPAudioRecorderErrorTypeStopFail,
    BDPAudioRecorderErrorTypeResumeFail,
    BDPAudioRecorderErrorTypeStartLockMutexFail,
    BDPAudioRecorderErrorTypeResumeLockMutexFail,
    BDPAudioRecorderErrorTypeCreateQueueFail,
    BDPAudioRecorderErrorTypeGetQueuePropertyFail,
    BDPAudioRecorderErrorTypeAddListenerFail,
    BDPAudioRecorderErrorTypeCreateFileFail,
    BDPAudioRecorderErrorTypeAllocateBufferFail,
    BDPAudioRecorderErrorTypeEnqueueBufferFail,
};

// fireEvent的实现
typedef void(^RecorderStateChangeBlock)(NSDictionary * _Nonnull data);

@interface BDPStreamingAudioRecorder : NSObject

@property (nonatomic, copy, nullable) RecorderStateChangeBlock stateChangeBlock;

@property (nonatomic, strong, nullable) OPAppUniqueID *uniqueID;

+ (instancetype)shareInstance;

// OPPlugin 调用
- (void)operateState:(NSDictionary * _Nullable)action completion:(void(^_Nonnull)(BDPAudioRecorderErrorType type, NSString * _Nullable errMsg))completion;

- (void)forceStopRecorder; // 强制停止录音，在退出小程序或者关闭音频权限时调用 by zhangquan

@end
