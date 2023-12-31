//
//  TSPKMediaNotificationObserver.m
//  Indexer
//
//  Created by bytedance on 2022/2/22.
//

#import "TSPKMediaNotificationObserver.h"
#import <AVFoundation/AVFoundation.h>
#import "NSObject+TSDeallocAssociate.h"
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"
#import <AVFAudio/AVAudioSession.h>
#import "TSPKLock.h"
#import "TSPKUtils.h"
#import <TSPrivacyKit/TSPKSignalManager+public.h>

@interface TSPKMediaNotificationObserver ()

@property (nonatomic, strong) id<TSPKLock> lock;
@property (nonatomic, strong) NSMutableDictionary *mutableInfo;

@end

@implementation TSPKMediaNotificationObserver

+ (instancetype)sharedObserver
{
    static TSPKMediaNotificationObserver *utils;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        utils = [[TSPKMediaNotificationObserver alloc] init];
    });
    return utils;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _lock = [TSPKLockFactory getLock];
        _mutableInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (void)setup {
    [[TSPKMediaNotificationObserver sharedObserver] setup];
}

- (void)setup
{
    static dispatch_once_t setupToken;
    dispatch_once(&setupToken, ^{
        [self addNotifications];
    });
}

- (void)addNotifications
{
#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRuntimeErrorNotification:) name:AVCaptureSessionRuntimeErrorNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidStartRunningNotification:) name:AVCaptureSessionDidStartRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidStopRunningNotification:) name:AVCaptureSessionDidStopRunningNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruptedNotification:) name:AVCaptureSessionWasInterruptedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleInterruptionEndedNotification:) name:AVCaptureSessionInterruptionEndedNotification object:nil];
#endif
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioSessionInterruptionNotification:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioSessionMediaServicesWereLostNotification:) name:AVAudioSessionMediaServicesWereLostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAudioSessionMediaServicesWereResetNotification:) name:AVAudioSessionMediaServicesWereResetNotification object:nil];
}

#if !defined(TARGET_OS_VISION) || !TARGET_OS_VISION
- (void)handleRuntimeErrorNotification:(NSNotification *)notification {
    AVCaptureSession *session = notification.object;
    
    NSError *error;
    if ([notification.userInfo[AVCaptureSessionErrorKey] isKindOfClass:[NSError class]]) {
        error = notification.userInfo[AVCaptureSessionErrorKey];
        
        if (error.code == AVErrorUnknown || error.code == AVErrorMediaServicesWereReset) {
            [self.lock lock];
            self.mutableInfo[TSPKDataTypeVideo] = @([TSPKUtils getRelativeTime]);
            [self.lock unlock];
        }
    }
    NSString *message = [NSString stringWithFormat:@"AVCaptureSessionRuntimeErrorNotification instance:%@ error:%@", [session ts_hashTag], error.description];
    [TSPKLogger logWithTag:TSPKLogCheckTag message:message];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeSystem permissionType:TSPKDataTypeVideo content:message];
}

- (void)handleDidStartRunningNotification:(NSNotification *)notification {
    AVCaptureSession *session = notification.object;
    
    NSString *message = @"AVCaptureSessionDidStartRunningNotification";
    [TSPKSignalManager addInstanceSignalWithType:TSPKSignalTypeSystem
                                  permissionType:TSPKDataTypeVideo
                                         content:message
                                 instanceAddress:[session ts_hashTag]];
    message = [NSString stringWithFormat:@"%@ instance:%@", message, [session ts_hashTag]];
    [TSPKLogger logWithTag:TSPKLogCheckTag message:message];
}

- (void)handleDidStopRunningNotification:(NSNotification *)notification {
    // An AVCaptureSession instance may stop running automatically due to external system conditions, such as the device going to sleep, or being locked by a user.
    AVCaptureSession *session = notification.object;
    NSString *message = @"AVCaptureSessionDidStopRunningNotification";
    [TSPKSignalManager addInstanceSignalWithType:TSPKSignalTypeSystem
                                  permissionType:TSPKDataTypeVideo
                                         content:message
                                 instanceAddress:[session ts_hashTag]];
    message = [NSString stringWithFormat:@"%@ instance:%@", message, [session ts_hashTag]];
    [TSPKLogger logWithTag:TSPKLogCheckTag message:message];
}

- (void)handleInterruptedNotification:(NSNotification *)notification {
    AVCaptureSession *session = notification.object;
    
    NSInteger reason = 0;
    if ([notification.userInfo[AVCaptureSessionInterruptionReasonKey] isKindOfClass:[NSNumber class]]) {
        reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    }
    
    NSString *content;
    switch (reason) {
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableInBackground:
        {
            content = @"VideoDeviceNotAvailableInBackground";
            break;
        }
        case AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient:
        {
            content = @"AudioDeviceInUseByAnotherClient";
            break;
        }
        case AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient:
        {
            content = @"VideoDeviceInUseByAnotherClient";
            break;
        }
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps:
        {
            content = @"VideoDeviceNotAvailableWithMultipleForegroundApps";
            break;
        }
        case AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableDueToSystemPressure:
        {
            content = @"VideoDeviceNotAvailableDueToSystemPressure";
            break;
        }
        default:
        {
            content = @"unknown reason";
            break;
        }
    }
    
    NSString *message = [NSString stringWithFormat:@"AVCaptureSessionWasInterruptedNotification instance:%@ reason:%@", [session ts_hashTag], content];
    [TSPKLogger logWithTag:TSPKLogCheckTag message:message];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeSystem permissionType:TSPKDataTypeVideo content:message];
}

- (void)handleInterruptionEndedNotification:(NSNotification *)notification {
    AVCaptureSession *session = notification.object;
    
    NSString *message = [NSString stringWithFormat:@"AVCaptureSessionInterruptionEndedNotification instance:%@", [session ts_hashTag]];
    [TSPKLogger logWithTag:TSPKLogCheckTag message:message];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeSystem permissionType:TSPKDataTypeVideo content:message];
}
#endif

- (void)handleAudioSessionInterruptionNotification:(NSNotification *)notification {
    NSString *message = @"AVAudioSessionInterruptionNotification";
    [TSPKLogger logWithTag:TSPKLogCheckTag message:message];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeSystem permissionType:TSPKDataTypeAudio content:message];
}

- (void)handleAudioSessionMediaServicesWereLostNotification:(NSNotification *)notification {
    NSString *message = @"AVAudioSessionMediaServicesWereLostNotification";
    [TSPKLogger logWithTag:TSPKLogCheckTag message:message];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeSystem permissionType:TSPKDataTypeAudio content:message];
}

- (void)handleAudioSessionMediaServicesWereResetNotification:(NSNotification *)notification {
    NSString *message = @"AVAudioSessionMediaServicesWereResetNotification";
    [TSPKLogger logWithTag:TSPKLogCheckTag message:message];
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeSystem permissionType:TSPKDataTypeAudio content:message];
}

+ (NSDictionary *)getInfoWithDataType:(NSString *)dataType {
    return [[TSPKMediaNotificationObserver sharedObserver] getInfoWithDataType:dataType];
}

- (NSDictionary *)getInfoWithDataType:(NSString *)dataType {
    if (dataType.length == 0) {
        return nil;
    }
    
    [self.lock lock];
    id detail = self.mutableInfo[dataType];
    [self.lock unlock];
    
    if (detail && dataType) {
        NSString *key = [NSString stringWithFormat:@"%@MediaResetTimestamp", [dataType capitalizedString]];
        return @{key : detail};
    }
    
    return nil;
}

@end
