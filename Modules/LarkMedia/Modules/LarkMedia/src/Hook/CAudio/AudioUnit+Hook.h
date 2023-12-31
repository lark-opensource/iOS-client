//
//  AudioUnit+Hook.h
//  AudioSessionScenario
//
//  Created by fakegourmet on 2022/2/22.
//

#include <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^LogHandler)(NSString* log);
typedef void(^AudioUnitHandler)(OSStatus result);
typedef BOOL(^AudioUnitWillMuteOutputHandler)(BOOL isMuted);
typedef void(^AudioUnitDidMuteOutputHandler)(BOOL isMuted, OSStatus result);

@interface AVAudioSession (Hook)

/// 获取当前函数的调用者地址
+(NSString *)callReturnAddress;

+(int)hookAudioUnit;

+(void)setLogHandler: (LogHandler)handler;

+(void)setWillStartHandler: (AudioUnitHandler)willHandler didStartHandler: (AudioUnitHandler)didHandler;
+(void)setWillStopHandler: (AudioUnitHandler)willHandler didStopHandler: (AudioUnitHandler)didHandler;
+(void)setWillMuteOutputHandler: (AudioUnitWillMuteOutputHandler)willHandler didMuteOutputHandler: (AudioUnitDidMuteOutputHandler)didHandler;

/// Swift performSelector 无法获取该属性，因此使用 OC 获取
+(NSObject* _Nullable)sharedApplication;
-(BOOL)isInputMuted;
-(BOOL)setInputMuted:(BOOL)muted error:(NSError * _Nullable *)outError;

@end

NS_ASSUME_NONNULL_END

