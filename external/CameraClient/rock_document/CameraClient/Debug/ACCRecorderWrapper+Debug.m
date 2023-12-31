//
//  ACCRecorderWrapper+Debug.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/6/6.
//

#if DEBUG || INHOUSE_TARGET

#import "ACCRecorderWrapper+Debug.h"

#import "ACCCreativePathMessage.h"
#import <HTSServiceKit/HTSMessageCenter.h>
#import <AWELazyRegister/AWELazyRegisterPremain.h>

@implementation ACCRecorderWrapper (Debug)

AWELazyRegisterPremainClassCategory(ACCRecorderWrapper, Debug)
{
    [self acc_swizzleInstanceMethod:@selector(setBalanceEnabled:targetLufs:) with:@selector(accdebug_setBalanceEnabled:targetLufs:)];
    [self acc_swizzleInstanceMethod:@selector(setTimeAlignEnabled:modelPath:timeAlignCallback:) with:@selector(accdebug_setTimeAlignEnabled:modelPath:timeAlignCallback:)];
    [self acc_swizzleInstanceMethod:@selector(setAECEnabled:modelPath:) with:@selector(accdebug_setAECEnabled:modelPath:)];
    [self acc_swizzleInstanceMethod:@selector(setEnableEarBack:) with:@selector(accdebug_setEnableEarBack:)];
    [self acc_swizzleInstanceMethod:@selector(setBackendMode:useOutput:) with:@selector(accdebug_setBackendMode:useOutput:)];
    [self acc_swizzleInstanceMethod:@selector(setUseOutput:) with:@selector(accdebug_setUseOutput:)];
    [self acc_swizzleInstanceMethod:@selector(setForceRecordAudio:) with:@selector(accdebug_setForceRecordAudio:)];
}

- (void)accdebug_setBalanceEnabled:(BOOL)enabled targetLufs:(int)lufs
{
    [ACCAcousticAlgorithmDebugger sharedInstance].lufs = lufs;
    [ACCAcousticAlgorithmDebugger sharedInstance].LEEnabled = enabled;
    [self accdebug_setBalanceEnabled:enabled targetLufs:lufs];
}

- (void)accdebug_setTimeAlignEnabled:(BOOL)enabled modelPath:(NSString *)timeAlignPath timeAlignCallback:(void (^)(float))callback
{
    [ACCAcousticAlgorithmDebugger sharedInstance].DAEnabled = enabled;
    void(^wrapper)(float) = ^(float ret) {
        [ACCAcousticAlgorithmDebugger sharedInstance].delay = ret;
        callback ? callback(ret) : nil;
    };
    if (!enabled) {
        [ACCAcousticAlgorithmDebugger sharedInstance].delay = 0;
    }
    [self accdebug_setTimeAlignEnabled:enabled modelPath:timeAlignPath timeAlignCallback:wrapper];
}

- (void)accdebug_setAECEnabled:(BOOL)isEnable modelPath:(NSString * _Nullable)path
{
    [ACCAcousticAlgorithmDebugger sharedInstance].AECEnabled = isEnable;
    [self accdebug_setAECEnabled:isEnable modelPath:path];
}

- (void)accdebug_setEnableEarBack:(BOOL)enable
{
    [ACCAcousticAlgorithmDebugger sharedInstance].EBEnabled = enable;
    [self accdebug_setEnableEarBack:enable];
}

- (void)accdebug_setBackendMode:(VERecorderBackendMode)backendMode useOutput:(BOOL)useOutput
{
    [ACCAcousticAlgorithmDebugger sharedInstance].backendMode = backendMode;
    [ACCAcousticAlgorithmDebugger sharedInstance].useOutput = useOutput;
    [self accdebug_setBackendMode:backendMode useOutput:useOutput];
}

- (void)accdebug_setUseOutput:(BOOL)useOutput
{
    [ACCAcousticAlgorithmDebugger sharedInstance].useOutput = useOutput;
    [self accdebug_setUseOutput:useOutput];
}

- (void)accdebug_setForceRecordAudio:(BOOL)forceRecordAudio
{
    [ACCAcousticAlgorithmDebugger sharedInstance].forceRecordAudio = forceRecordAudio;
    [self accdebug_setForceRecordAudio:forceRecordAudio];
}

@end


@interface ACCAcousticAlgorithmDebugger () <ACCCreativePathMessage>

@end

@implementation ACCAcousticAlgorithmDebugger

+ (ACCAcousticAlgorithmDebugger *)sharedInstance
{
    static dispatch_once_t onceToken;
    static ACCAcousticAlgorithmDebugger *obj;
    dispatch_once(&onceToken, ^{
        obj = [[ACCAcousticAlgorithmDebugger alloc] init];
        REGISTER_MESSAGE(ACCCreativePathMessage, obj);
    });
    return obj;
}

- (void)exitCreativePath
{
    self.AECEnabled = NO;
    self.DAEnabled = NO;
    self.LEEnabled = NO;
    self.EBEnabled = NO;
    self.lufs = 0;
    self.delay = 0;
    self.backendMode = VERecorderBackendMode_None;
    self.useOutput = NO;
    self.forceRecordAudio = NO;
}

@end

#endif
