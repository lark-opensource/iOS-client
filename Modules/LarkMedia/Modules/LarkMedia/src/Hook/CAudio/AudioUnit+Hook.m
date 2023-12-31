//
//  AudioUnit+Hook.m
//  AudioSessionScenario
//
//  Created by fakegourmet on 2022/2/22.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <BDFishhook/BDFishhook.h>
#import "AudioUnit+Hook.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation AVAudioSession (Hook)

static LogHandler logger;

static AudioUnitHandler audioUnitWillStartHandler;
static AudioUnitHandler audioUnitDidStartHandler;

static AudioUnitHandler audioUnitWillStopHandler;
static AudioUnitHandler audioUnitDidStopHandler;

static AudioUnitWillMuteOutputHandler willMuteOutputHandler;
static AudioUnitDidMuteOutputHandler didMuteOutputHandler;

+ (void)setLogHandler:(LogHandler)handler {
    logger = handler;
}

+(void)setWillStartHandler: (AudioUnitHandler)willHandler didStartHandler: (AudioUnitHandler)didHandler {
    audioUnitWillStartHandler = willHandler;
    audioUnitDidStartHandler = didHandler;
}

+(void)setWillStopHandler: (AudioUnitHandler)willHandler didStopHandler: (AudioUnitHandler)didHandler {
    audioUnitWillStopHandler = willHandler;
    audioUnitDidStopHandler = didHandler;
}

+(void)setWillMuteOutputHandler: (AudioUnitWillMuteOutputHandler)willHandler didMuteOutputHandler: (AudioUnitDidMuteOutputHandler)didHandler {
    willMuteOutputHandler = willHandler;
    didMuteOutputHandler = didHandler;
}

+(NSString *)callReturnAddress {
    void *ptr1  = __builtin_extract_return_addr(__builtin_return_address(1));
    void *ptr2  = __builtin_extract_return_addr(__builtin_return_address(2));
    void *ptr3  = __builtin_extract_return_addr(__builtin_return_address(3));
    void *ptr4  = __builtin_extract_return_addr(__builtin_return_address(4));
    void *ptr5  = __builtin_extract_return_addr(__builtin_return_address(5));
    void *ptr6  = __builtin_extract_return_addr(__builtin_return_address(6));
    return [NSString stringWithFormat:@"[%p %p %p %p %p %p]", ptr1, ptr2, ptr3, ptr4, ptr5, ptr6];
}

+(int)hookAudioUnit {
    struct bd_rebinding r[] = {
        makeRebinding("AudioOutputUnitStart", new_AudioOutputUnitStart, (void *)&old_AudioOutputUnitStart),
        makeRebinding("AudioOutputUnitStop", new_AudioOutputUnitStop, (void *)&old_AudioOutputUnitStop),
        makeRebinding("AudioUnitSetProperty", new_AudioUnitSetProperty, (void *)&old_AudioUnitSetProperty),
        makeRebinding("AudioQueueStart", new_AudioQueueStart, (void *)&old_AudioQueueStart),
        makeRebinding("AudioQueueStop", new_AudioQueueStop, (void *)&old_AudioQueueStop),
    };
    return bd_rebind_symbols(r, sizeof(r)/sizeof(struct bd_rebinding));
}

static struct bd_rebinding makeRebinding(char* name, void* replacement, void** replaced) {
    struct bd_rebinding rebinding;
    rebinding.name = name;
    rebinding.replacement = replacement;
    rebinding.replaced = replaced;
    return rebinding;
}

static OSStatus (*old_AudioOutputUnitStart)(AudioUnit ci);
static OSStatus new_AudioOutputUnitStart(AudioUnit ci) {
    if (logger) {
        logger([NSString stringWithFormat:@"lk_AudioOutputUnitStart, address: %p", __builtin_extract_return_addr(__builtin_return_address(0))]);
    }
    if (audioUnitWillStartHandler) {
        audioUnitWillStartHandler(noErr);
    }
    OSStatus result = old_AudioOutputUnitStart(ci);
    if (audioUnitDidStartHandler) {
        audioUnitDidStartHandler(result);
    }
    return result;
}

static OSStatus (*old_AudioOutputUnitStop)(AudioUnit ci);
static OSStatus new_AudioOutputUnitStop(AudioUnit ci) {
    if (logger) {
        logger([NSString stringWithFormat:@"lk_AudioOutputUnitStop, address: %p", __builtin_extract_return_addr(__builtin_return_address(0))]);
    }
    if (audioUnitWillStopHandler) {
        audioUnitWillStopHandler(noErr);
    }
    OSStatus result = old_AudioOutputUnitStop(ci);
    if (audioUnitDidStopHandler) {
        audioUnitDidStopHandler(result);
    }
    return result;
}

static OSStatus (*old_AudioUnitSetProperty)(AudioUnit                inUnit,
                                            AudioUnitPropertyID        inID,
                                            AudioUnitScope            inScope,
                                            AudioUnitElement        inElement,
                                            const void * __nullable    inData,
                                            UInt32                    inDataSize);
static OSStatus new_AudioUnitSetProperty(AudioUnit                inUnit,
                                         AudioUnitPropertyID        inID,
                                         AudioUnitScope            inScope,
                                         AudioUnitElement        inElement,
                                         const void * __nullable    inData,
                                         UInt32                    inDataSize) {
    if (logger) {
        logger([NSString stringWithFormat:@"lk_AudioUnitSetProperty, value: %d, address: %p", inID, __builtin_extract_return_addr(__builtin_return_address(0))]);
    }
    if (inID == kAUVoiceIOProperty_MuteOutput) {
        UInt32 data = 0;
        if (inData) {
            data = *(UInt32 *)(inData);
        }
        BOOL isMuted = data > 0;
        BOOL shouldExecute = YES;
        if (willMuteOutputHandler) {
            shouldExecute = willMuteOutputHandler(isMuted);
        }
        OSStatus result = -1;
        if (shouldExecute) {
            result = old_AudioUnitSetProperty(inUnit, inID, inScope, inElement, inData, inDataSize);
        }
        if (didMuteOutputHandler) {
            didMuteOutputHandler(isMuted, result);
        }
        return result;
    } else {
        OSStatus result = old_AudioUnitSetProperty(inUnit, inID, inScope, inElement, inData, inDataSize);
        return result;
    }
}

static OSStatus (*old_AudioQueueStart)(AudioQueueRef inAQ,
                                       const AudioTimeStamp * __nullable inStartTime);
static OSStatus new_AudioQueueStart(AudioQueueRef inAQ,
                                    const AudioTimeStamp * __nullable inStartTime) {
    if (logger) {
        logger([NSString stringWithFormat:@"lk_AudioQueueStart, address: %p", __builtin_extract_return_addr(__builtin_return_address(0))]);
    }
    OSStatus result = old_AudioQueueStart(inAQ, inStartTime);
    return result;
}

static OSStatus (*old_AudioQueueStop)(AudioQueueRef inAQ,
                                      const AudioTimeStamp * __nullable inStartTime);
static OSStatus new_AudioQueueStop(AudioQueueRef inAQ,
                                   const AudioTimeStamp * __nullable inStartTime) {
    if (logger) {
        logger([NSString stringWithFormat:@"lk_AudioQueueStop, address: %p", __builtin_extract_return_addr(__builtin_return_address(0))]);
    }
    OSStatus result = old_AudioQueueStop(inAQ, inStartTime);
    return result;
}

-(BOOL)isInputMuted {
    if (@available(iOS 17, *)) {
        SEL sel = NSSelectorFromString(@"isInputMuted");
        NSObject* _Nullable application = [AVAudioSession sharedApplication];
        if (application && sel) {
            if ([application respondsToSelector:sel]) {
                BOOL isInputMuted = [application performSelector:sel];
                return isInputMuted;
            }
        }
    }
    return NO;
}

-(BOOL)setInputMuted:(BOOL)muted error:(NSError * _Nullable *)outError {
    if (@available(iOS 17, *)) {
        Class cls = NSClassFromString(@"AVAudioApplication");
        SEL sel = NSSelectorFromString(@"setInputMuted:error:");
        NSObject* _Nullable application = [AVAudioSession sharedApplication];
        if (cls && application && sel) {
            if ([application respondsToSelector:sel]) {
                NSMethodSignature* signature = [cls instanceMethodSignatureForSelector: sel];
                NSInvocation* invocation = [NSInvocation invocationWithMethodSignature: signature];
                [invocation setTarget: application];
                [invocation setSelector: sel];
                [invocation setArgument: &muted atIndex: 2];
                [invocation setArgument: &outError atIndex: 3];
                [invocation invoke];
                BOOL ret = NO;
                [invocation getReturnValue:&ret];
                return ret;
            }
        }
    }
    return NO;
}

+(NSObject* _Nullable)sharedApplication {
    if (@available(iOS 17, *)) {
        Class cls = NSClassFromString(@"AVAudioApplication");
        SEL sel = NSSelectorFromString(@"sharedInstance");
        if (cls && sel) {
            if ([cls respondsToSelector:sel]) {
                return [cls performSelector:sel];
            }
        }
    }
    return nil;
}

@end
