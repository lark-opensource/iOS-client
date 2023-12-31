//
//  TSPKAudioOfAudioOutputPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/12.
//

#import "TSPKAudioOfAudioOutputPipeline.h"

#include <BDFishhook/BDFishhook.h>
#import <AudioToolbox/AudioOutputUnit.h>
#import <AVFoundation/AVFoundation.h>
#import "TSPrivacyKitConstants.h"
#import "TSPKFishhookUtils.h"

@interface TSPKAudioOfAudioOutputPipeline ()

+ (TSPKHandleResult *_Nullable)forwardEventWithMethodName:(NSString *)method
                                             apiUsageType:(TSPKAPIUsageType)apiUsageType
                                                       ci:(AudioUnit)ci
                                                   status:(OSStatus)status
                                            isNonsenstive:(BOOL)isNonsenstive
                                             apiStoreType:(TSPKAPIStoreType)apiStoreType
                                              isDowngrade:(BOOL)isDowngrade;

+ (TSPKHandleResult *)forwardEventWithMethodName:(NSString *)method
                                    apiUsageType:(TSPKAPIUsageType)apiUsageType
                                              ci:(AudioUnit)ci
                                          status:(OSStatus)status
                                   isNonsenstive:(BOOL)isNonsenstive
                                     isDowngrade:(BOOL)isDowngrade;

@end

static OSStatus (*tspk_OldAudioOutputUnitStart)(AudioUnit);
static OSStatus (*tspk_OldAudioOutputUnitStop)(AudioUnit);
static OSStatus (*tspk_OldAudioUnitUninitialize)(AudioUnit);
static OSStatus (*tspk_OldAudioComponentInstanceDispose)(AudioComponentInstance);

static inline BOOL tspk_IsRecorderAudioUnit(AudioUnit au) {
    UInt32 flag;
    UInt32 size = sizeof(UInt32);
    AudioUnitGetProperty(au, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, &size);
    if (flag != 1) {
        return NO;
    }
    AudioComponent component = AudioComponentInstanceGetComponent(au);
    AudioComponentDescription description;
    AudioComponentGetDescription(component, &description);
    if (description.componentType != kAudioUnitType_Output) {
       return NO;
    }
    return YES;
}

static NSString *const audioOutputUnitStop = @"AudioOutputUnitStop";
OSStatus tspk_NewAudioOutputUnitStopImp(AudioUnit ci, BOOL isDowngrade) {
    @autoreleasepool {
        NSString *methodName = audioOutputUnitStop;
        
        if (ci != NULL && tspk_IsRecorderAudioUnit(ci)) {
            [TSPKAudioOfAudioOutputPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStop hashTag:[NSString stringWithFormat:@"%p", ci] beforeOrAfter:YES];
        }
        
        OSStatus status = tspk_OldAudioOutputUnitStop(ci);
        
        if (ci == NULL) {
            return status;
        }
        
        //continue process when it is recording
        if (!tspk_IsRecorderAudioUnit(ci)) {
            return status;
        }
        
        [TSPKAudioOfAudioOutputPipeline forwardEventWithMethodName:methodName apiUsageType:TSPKAPIUsageTypeStop ci:ci status:status isNonsenstive:YES  isDowngrade:isDowngrade];
        [TSPKAudioOfAudioOutputPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStop hashTag:[NSString stringWithFormat:@"%p", ci] beforeOrAfter:NO];
        
        return status;
    }
}

static NSString *const audioOutputUnitStart = @"AudioOutputUnitStart";
OSStatus tspk_NewAudioOutputUnitStart(AudioUnit ci) {
    @autoreleasepool {
        NSString *methodName = audioOutputUnitStart;
        if (ci != NULL && tspk_IsRecorderAudioUnit(ci)) {
            [TSPKAudioOfAudioOutputPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStart hashTag:[NSString stringWithFormat:@"%p", ci] beforeOrAfter:YES];
            
            TSPKHandleResult *result = [TSPKAudioOfAudioOutputPipeline forwardEventWithMethodName:methodName apiUsageType:TSPKAPIUsageTypeStart ci:ci status:noErr isNonsenstive:NO apiStoreType:TSPKAPIStoreTypeIgnoreStore isDowngrade:NO];
            /// contact with @zhaomingwei, if return value unequal to noError(0), vesdk will do nothing.
            if (result.action == TSPKResultActionFuse) {
                [TSPKAudioOfAudioOutputPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStart hashTag:[NSString stringWithFormat:@"%p", ci] beforeOrAfter:NO];

                return -1;
            }
        }
        
        OSStatus status = tspk_OldAudioOutputUnitStart(ci);
        
        if (status != noErr) {
            return status;
        }
        
        if (ci == NULL) {
            return status;
        }
        
        //continue process when it is recording
        if (!tspk_IsRecorderAudioUnit(ci)) {
            return status;
        }
        
        [TSPKAudioOfAudioOutputPipeline forwardEventWithMethodName:methodName apiUsageType:TSPKAPIUsageTypeStart ci:ci status:noErr isNonsenstive:NO apiStoreType:TSPKAPIStoreTypeOnlyStore isDowngrade:NO];

        [TSPKAudioOfAudioOutputPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStart hashTag:[NSString stringWithFormat:@"%p", ci] beforeOrAfter:NO];
        
        return status;
    }
}

OSStatus tspk_NewAudioOutputUnitStop(AudioUnit ci) {
    return tspk_NewAudioOutputUnitStopImp(ci, NO);
}

static NSString *const audioUnitUninitialize = @"AudioUnitUninitialize";
OSStatus tspk_NewAudioUnitUninitialize(AudioUnit ci) {
    @autoreleasepool {
        if (ci == NULL) {
            return tspk_OldAudioUnitUninitialize(ci);
        }
        
        BOOL isRecordUnit = tspk_IsRecorderAudioUnit(ci);
        
        OSStatus status = tspk_OldAudioUnitUninitialize(ci);
        
        //continue process when it is recording
        if (!isRecordUnit) {
            return status;
        }
        
        [TSPKAudioOfAudioOutputPipeline forwardEventWithMethodName:audioUnitUninitialize apiUsageType:TSPKAPIUsageTypeDealloc ci:ci status:status isNonsenstive:YES isDowngrade:NO];
        
        return status;
    }
}

static NSString *const audioComponentInstanceDispose = @"AudioComponentInstanceDispose";
OSStatus tspk_NewAudioComponentInstanceDispose(AudioComponentInstance ci) {
    @autoreleasepool {
        if (ci == NULL) {
            return tspk_OldAudioComponentInstanceDispose(ci);
        }
        
        BOOL isRecordUnit = tspk_IsRecorderAudioUnit(ci);
        
        OSStatus status = tspk_OldAudioComponentInstanceDispose(ci);
        
        //continue process when it is recording
        if (!isRecordUnit) {
            return status;
        }

        [TSPKAudioOfAudioOutputPipeline forwardEventWithMethodName:audioComponentInstanceDispose apiUsageType:TSPKAPIUsageTypeDealloc ci:ci status:status isNonsenstive:YES isDowngrade:NO];
        
        return status;
    }
}

@implementation TSPKAudioOfAudioOutputPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAudioOfAudioOutput;
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
    return @[@"AudioOutputUnitStart", @"AudioOutputUnitStop", @"AudioUnitUninitialize", @"AudioComponentInstanceDispose"];
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
        struct bd_rebinding audioStart;
        audioStart.name = "AudioOutputUnitStart";
        audioStart.replacement = tspk_NewAudioOutputUnitStart;
        audioStart.replaced = (void *)&tspk_OldAudioOutputUnitStart;

        struct bd_rebinding audioStop;
        audioStop.name = "AudioOutputUnitStop";
        audioStop.replacement = tspk_NewAudioOutputUnitStop;
        audioStop.replaced = (void *)&tspk_OldAudioOutputUnitStop;
        
        struct bd_rebinding audioUnintialize;
        audioUnintialize.name = "AudioUnitUninitialize";
        audioUnintialize.replacement = tspk_NewAudioUnitUninitialize;
        audioUnintialize.replaced = (void *)&tspk_OldAudioUnitUninitialize;
        
        struct bd_rebinding audioDispose;
        audioDispose.name = "AudioComponentInstanceDispose";
        audioDispose.replacement = tspk_NewAudioComponentInstanceDispose;
        audioDispose.replaced = (void *)&tspk_OldAudioComponentInstanceDispose;
        
        struct bd_rebinding rebs[]={audioStart,audioStop,audioUnintialize,audioDispose};
        tspk_rebind_symbols(rebs, 4);
    });
}

- (BOOL)deferPreload
{
    return YES;
}

+ (TSPKHandleResult *)forwardEventWithMethodName:(NSString *)method
                                    apiUsageType:(TSPKAPIUsageType)apiUsageType
                                              ci:(AudioUnit)ci
                                          status:(OSStatus)status
                                   isNonsenstive:(BOOL)isNonsenstive
                                     isDowngrade:(BOOL)isDowngrade {
    return [self forwardEventWithMethodName:method
                               apiUsageType:apiUsageType
                                         ci:ci
                                     status:status
                              isNonsenstive:isNonsenstive
                               apiStoreType:TSPKAPIStoreTypeNormal
                                isDowngrade:isDowngrade];
}

+ (TSPKHandleResult *)forwardEventWithMethodName:(NSString *)method
                                    apiUsageType:(TSPKAPIUsageType)apiUsageType
                                              ci:(AudioUnit)ci
                                          status:(OSStatus)status
                                   isNonsenstive:(BOOL)isNonsenstive
                                    apiStoreType:(TSPKAPIStoreType)apiStoreType
                                     isDowngrade:(BOOL)isDowngrade {
    
    return [self handleAPIAccess:method className:nil params:nil customHandleBlock:^(TSPKAPIModel * _Nonnull apiModel) {
        apiModel.apiUsageType = apiUsageType;
        apiModel.instance = nil;
        apiModel.hashTag = [NSString stringWithFormat:@"%p", ci];
        apiModel.isNonsenstive = isNonsenstive;
        apiModel.errorCode = status == noErr ? nil : [NSNumber numberWithInteger:status];
        apiModel.apiStoreType = apiStoreType;
        
        if (apiUsageType == TSPKAPIUsageTypeStart) {
            apiModel.downgradeAction = ^{
                tspk_NewAudioOutputUnitStopImp(ci, YES);
            };
        }
    }];
}

@end
