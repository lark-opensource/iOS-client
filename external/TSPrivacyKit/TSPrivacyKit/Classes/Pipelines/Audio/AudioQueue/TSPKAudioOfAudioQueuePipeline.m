//
//  TSPKAudioOfAudioQueuePipeline.m
//  Musically
//
//  Created by ByteDance on 2022/9/6.
//

#import "TSPKAudioOfAudioQueuePipeline.h"
#include <BDFishhook/BDFishhook.h>
#import <AudioToolBox/AudioToolBox.h>
#import "TSPrivacyKitConstants.h"
#import "TSPKFishhookUtils.h"

static NSString *const AudioQueueNewInputMethod = @"AudioQueueNewInput";
static NSString *const AudioQueueStartMethod = @"AudioQueueStart";
static NSString *const AudioQueueStopMethod = @"AudioQueueStop";
static NSString *const AudioQueueDisposeMethod = @"AudioQueueDispose";

@interface TSPKAudioOfAudioQueuePipeline ()

+ (TSPKHandleResult *)forwardEventWithMethodName:(NSString *)method
                                    apiUsageType:(TSPKAPIUsageType)apiUsageType
                                          status:(OSStatus)status
                                   isNonsenstive:(BOOL)isNonsenstive
                                            inAQ:(AudioQueueRef)inAQ
                                    apiStoreType:(TSPKAPIStoreType)apiStoreType;

@end

static OSStatus (*tspk_OldAudioQueueNewInput)(const AudioStreamBasicDescription *inFormat,
                                     AudioQueueInputCallback         inCallbackProc,
                                     void * __nullable               inUserData,
                                     CFRunLoopRef __nullable         inCallbackRunLoop,
                                     CFStringRef __nullable          inCallbackRunLoopMode,
                                     UInt32                          inFlags,
                                     AudioQueueRef __nullable * __nonnull outAQ) = AudioQueueNewInput;

static OSStatus tspk_NewAudioQueueNewInput(const AudioStreamBasicDescription *inFormat,
                                  AudioQueueInputCallback         inCallbackProc,
                                  void * __nullable               inUserData,
                                  CFRunLoopRef __nullable         inCallbackRunLoop,
                                  CFStringRef __nullable          inCallbackRunLoopMode,
                                  UInt32                          inFlags,
                                  AudioQueueRef __nullable * __nonnull outAQ)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKAudioOfAudioQueuePipeline handleAPIAccess:AudioQueueNewInputMethod];
        if (result.action == TSPKResultActionFuse) {
            return -1;
        } else {
            return tspk_OldAudioQueueNewInput(inFormat, inCallbackProc, inUserData, inCallbackRunLoop, inCallbackRunLoopMode, inFlags, outAQ);
        }
    }
}

static OSStatus (*tspk_OldAudioQueueStart)(AudioQueueRef inAQ,
                                           const AudioTimeStamp * __nullable inStartTime) = AudioQueueStart;

static OSStatus tspk_NewAudioQueueStart(AudioQueueRef inAQ,
                                        const AudioTimeStamp * __nullable inStartTime) {
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKAudioOfAudioQueuePipeline forwardEventWithMethodName:AudioQueueStartMethod
                                                                                apiUsageType:TSPKAPIUsageTypeStart
                                                                                      status:noErr
                                                                                isNonsenstive:NO
                                                                                        inAQ:inAQ
                                                                                apiStoreType:TSPKAPIStoreTypeIgnoreStore];
        if (result.action == TSPKResultActionFuse) {
            return -1;
        } else {
            OSStatus status = tspk_OldAudioQueueStart(inAQ, inStartTime);
            if (status != noErr) {
                return status;
            }
            TSPKHandleResult *result = [TSPKAudioOfAudioQueuePipeline forwardEventWithMethodName:AudioQueueStartMethod
                                                                                    apiUsageType:TSPKAPIUsageTypeStart
                                                                                          status:status
                                                                                    isNonsenstive:NO
                                                                                            inAQ:inAQ
                                                                                    apiStoreType:TSPKAPIStoreTypeOnlyStore];
            return status;
        }
    }
}

static OSStatus (*tspk_OldAudioQueueStop)(AudioQueueRef inAQ, Boolean inImmediate) = AudioQueueStop;

static OSStatus tspk_NewAudioQueueStop(AudioQueueRef inAQ, Boolean inImmediate) {
    @autoreleasepool {
        OSStatus status = tspk_OldAudioQueueStop(inAQ, inImmediate);
        TSPKHandleResult *result = [TSPKAudioOfAudioQueuePipeline forwardEventWithMethodName:AudioQueueStopMethod
                                                                                apiUsageType:TSPKAPIUsageTypeStop
                                                                                      status:status
                                                                                isNonsenstive:YES
                                                                                        inAQ:inAQ
                                                                                apiStoreType:TSPKAPIStoreTypeOnlyStore];
        return status;
    }
}

static OSStatus (*tspk_OldAudioQueueDispose)(AudioQueueRef inAQ, Boolean inImmediate) = AudioQueueDispose;

static OSStatus tspk_NewAudioQueueDispose(AudioQueueRef inAQ, Boolean inImmediate) {
    @autoreleasepool {
        OSStatus status = tspk_OldAudioQueueDispose(inAQ, inImmediate);
        TSPKHandleResult *result = [TSPKAudioOfAudioQueuePipeline forwardEventWithMethodName:AudioQueueStopMethod
                                                                                apiUsageType:TSPKAPIUsageTypeDealloc
                                                                                      status:status
                                                                                isNonsenstive:YES
                                                                                        inAQ:inAQ
                                                                                apiStoreType:TSPKAPIStoreTypeOnlyStore];
        return status;
    }
}

@implementation TSPKAudioOfAudioQueuePipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAudioOfAudioQueue;
}

+ (TSPKStoreType)storeType
{
    return TSPKStoreTypeRelationObjectCache;
}

+ (NSString *)dataType {
    return TSPKDataTypeAudio;
}

+ (NSArray<NSString *> * _Nullable)stubbedCAPIs
{
    return @[AudioQueueNewInputMethod, AudioQueueStartMethod, AudioQueueStopMethod, AudioQueueDisposeMethod];
}

+ (NSString *)stubbedClass
{
    return nil;
}

+ (BOOL)isEntryDefaultEnable
{
    return NO;
}

+ (void)preload
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding audioQueueNewInput;
        audioQueueNewInput.name = "AudioQueueNewInput";
        audioQueueNewInput.replacement = tspk_NewAudioQueueNewInput;
        audioQueueNewInput.replaced = (void *)&tspk_OldAudioQueueNewInput;
        
        struct bd_rebinding audioQueueStart;
        audioQueueStart.name = "AudioQueueStart";
        audioQueueStart.replacement = tspk_NewAudioQueueStart;
        audioQueueStart.replaced = (void *)&tspk_OldAudioQueueStart;
        
        struct bd_rebinding audioQueueStop;
        audioQueueStop.name = "AudioQueueStop";
        audioQueueStop.replacement = tspk_NewAudioQueueStop;
        audioQueueStop.replaced = (void *)&tspk_OldAudioQueueStop;
        
        struct bd_rebinding audioQueueDispose;
        audioQueueDispose.name = "AudioQueueDispose";
        audioQueueDispose.replacement = tspk_NewAudioQueueDispose;
        audioQueueDispose.replaced = (void *)&tspk_OldAudioQueueDispose;
        
        struct bd_rebinding rebs[]={audioQueueNewInput, audioQueueStart, audioQueueStop, audioQueueDispose};
        tspk_rebind_symbols(rebs, 4);
    });
}

- (BOOL)deferPreload
{
    return YES;
}

+ (TSPKHandleResult *)forwardEventWithMethodName:(NSString *)method
                                    apiUsageType:(TSPKAPIUsageType)apiUsageType
                                          status:(OSStatus)status
                                   isNonsenstive:(BOOL)isNonsenstive
                                            inAQ:(AudioQueueRef)inAQ
                                    apiStoreType:(TSPKAPIStoreType)apiStoreType {
    
    return [self handleAPIAccess:method className:nil params:nil customHandleBlock:^(TSPKAPIModel * _Nonnull apiModel) {
        apiModel.apiUsageType = apiUsageType;
        apiModel.instance = nil;
        apiModel.isNonsenstive = isNonsenstive;
        apiModel.errorCode = status == noErr ? nil : [NSNumber numberWithInteger:status];
        apiModel.hashTag = [NSString stringWithFormat:@"%p", inAQ];
        apiModel.apiStoreType = apiStoreType;
        if(apiUsageType == TSPKAPIUsageTypeStart) {
            apiModel.downgradeAction = ^{
                tspk_NewAudioQueueStop(inAQ, true);
            };
        }
    }];
}

@end
