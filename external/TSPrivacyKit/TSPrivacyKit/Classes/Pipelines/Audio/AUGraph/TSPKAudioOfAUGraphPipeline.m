//
//  TSPKAudioOfAUGraphPipeline.m
//  Musically
//
//  Created by ByteDance on 2022/9/6.
//

#import "TSPKAudioOfAUGraphPipeline.h"
#include <BDFishhook/BDFishhook.h>
#import <AudioToolbox/AUGraph.h>
#import <AVFoundation/AVFoundation.h>
#import "TSPrivacyKitConstants.h"
#import "TSPKFishhookUtils.h"

@interface TSPKAudioOfAUGraphPipeline ()

+ (TSPKHandleResult *_Nullable)forwardEventWithMethodName:(NSString *)method
                                             apiUsageType:(TSPKAPIUsageType)apiUsageType
                                                       graph:(AUGraph)graph
                                                   status:(OSStatus)status
                                            isNonsenstive:(BOOL)isNonsenstive
                                             apiStoreType:(TSPKAPIStoreType)apiStoreType
                                              isDowngrade:(BOOL)isDowngrade;

+ (TSPKHandleResult *)forwardEventWithMethodName:(NSString *)method
                                    apiUsageType:(TSPKAPIUsageType)apiUsageType
                                           graph:(AUGraph)graph
                                          status:(OSStatus)status
                                   isNonsenstive:(BOOL)isNonsenstive
                                     isDowngrade:(BOOL)isDowngrade;

@end

static OSStatus (*tspk_OldAUGraphStart)(AUGraph);
static OSStatus (*tspk_OldAUGraphStop)(AUGraph);
static OSStatus (*tspk_OldAUGraphUninitialize)(AUGraph);
static OSStatus (*tspk_OldDisposeAUGraph)(AUGraph);

static inline BOOL tspk_IsRecorderAUGraph(AUGraph graph) {
    if (graph == NULL) {
        return NO;
    }
    
    UInt32 count;
    
    AUGraphGetNodeCount(graph, &count);
    
    AUNode node;
    AudioComponentDescription description;
    AudioUnit au;
    UInt32 flag;
    UInt32 size = sizeof(UInt32);
    for (UInt32 index = 0; index < count; index ++) {
        AUGraphGetIndNode(graph, index, &node);
        AUGraphNodeInfo(graph, node, &description, &au);
        if (description.componentType != kAudioUnitType_Output) {
            continue;
        }
        
        if (au == NULL) {
            continue;
        }
        
        AudioUnitGetProperty(au, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flag, &size);
        
        if (flag == 1) {
            return YES;
        }
    }
    
    return NO;
}

static NSString *const auGraphStop = @"AUGraphStop";
OSStatus tspk_NewAUGraphStopImp(AUGraph graph, BOOL isDowngrade) {
    @autoreleasepool {
        NSString *methodName = auGraphStop;
        
        if (graph != NULL && tspk_IsRecorderAUGraph(graph)) {
            [TSPKAudioOfAUGraphPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStop hashTag:[NSString stringWithFormat:@"%p", graph] beforeOrAfter:YES];
        }

        OSStatus status = tspk_OldAUGraphStop(graph);

        if (graph == NULL) {
            return status;
        }

        //continue process when it is recording
        if (!tspk_IsRecorderAUGraph(graph)) {
            return status;
        }

        [TSPKAudioOfAUGraphPipeline forwardEventWithMethodName:methodName apiUsageType:TSPKAPIUsageTypeStop graph:graph status:status isNonsenstive:YES  isDowngrade:isDowngrade];
        [TSPKAudioOfAUGraphPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStop hashTag:[NSString stringWithFormat:@"%p", graph] beforeOrAfter:NO];

        return status;
    }
}
static NSString *const auGraphStart = @"AUGraphStart";
OSStatus tspk_NewAUGraphStart(AUGraph graph) {
    @autoreleasepool {
        NSString *methodName = auGraphStart;
        
        BOOL isRecord  = tspk_IsRecorderAUGraph(graph);
        
        if (graph != NULL && isRecord) {
            [TSPKAudioOfAUGraphPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStart hashTag:[NSString stringWithFormat:@"%p", graph] beforeOrAfter:YES];

            TSPKHandleResult *result = [TSPKAudioOfAUGraphPipeline forwardEventWithMethodName:methodName apiUsageType:TSPKAPIUsageTypeStart graph:graph status:noErr isNonsenstive:NO apiStoreType:TSPKAPIStoreTypeIgnoreStore isDowngrade:NO];
            /// contact with @zhaomingwei, if return value unequal to noError(0), vesdk will do nothing.
            if (result.action == TSPKResultActionFuse) {
                [TSPKAudioOfAUGraphPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStart hashTag:[NSString stringWithFormat:@"%p", graph] beforeOrAfter:NO];
                return -1;
            }
        }

        OSStatus status = tspk_OldAUGraphStart(graph);

        if (status != noErr) {
            return status;
        }

        if (graph == NULL) {
            return status;
        }

        //continue process when it is recording
        if (!isRecord) {
            return status;
        }

        [TSPKAudioOfAUGraphPipeline forwardEventWithMethodName:methodName apiUsageType:TSPKAPIUsageTypeStart graph:graph status:noErr isNonsenstive:NO apiStoreType:TSPKAPIStoreTypeOnlyStore isDowngrade:NO];

        [TSPKAudioOfAUGraphPipeline forwardCallInfoWithMethod:methodName className:nil apiUsageType:TSPKAPIUsageTypeStart hashTag:[NSString stringWithFormat:@"%p", graph] beforeOrAfter:NO];

        return status;
    }
}

OSStatus tspk_NewAUGraphStop(AUGraph graph) {
    return tspk_NewAUGraphStopImp(graph, NO);
}

static NSString *const auGraphUninitialize = @"AUGraphUninitialize";
OSStatus tspk_NewAUGraphUninitialize(AUGraph graph) {
    @autoreleasepool {
        if (graph == NULL) {
            return tspk_OldAUGraphUninitialize(graph);
        }

        BOOL isRecord = tspk_IsRecorderAUGraph(graph);

        OSStatus status = tspk_OldAUGraphUninitialize(graph);

        //continue process when it is recording
        if (!isRecord) {
            return status;
        }

        [TSPKAudioOfAUGraphPipeline forwardEventWithMethodName:auGraphUninitialize apiUsageType:TSPKAPIUsageTypeDealloc graph:graph status:status isNonsenstive:YES isDowngrade:NO];

        return status;
    }
}

static NSString *const disposeAUGraph = @"DisposeAUGraph";
OSStatus tspk_NewDisposeAUGraph(AUGraph graph) {
    @autoreleasepool {
        if (graph == NULL) {
            return tspk_OldDisposeAUGraph(graph);
        }

        BOOL isRecord = tspk_IsRecorderAUGraph(graph);

        OSStatus status = tspk_OldDisposeAUGraph(graph);

        //continue process when it is recording
        if (!isRecord) {
            return status;
        }

        [TSPKAudioOfAUGraphPipeline forwardEventWithMethodName:disposeAUGraph apiUsageType:TSPKAPIUsageTypeDealloc graph:graph status:status isNonsenstive:YES isDowngrade:NO];

        return status;
    }
}

@implementation TSPKAudioOfAUGraphPipeline

+ (NSString *)pipelineType
{
    return TSPKPipelineAudioOfAUGraph;
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
    return @[auGraphStart, auGraphStop, auGraphUninitialize, disposeAUGraph];
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
        audioStart.name = "AUGraphStart";
        audioStart.replacement = tspk_NewAUGraphStart;
        audioStart.replaced = (void *)&tspk_OldAUGraphStart;

        struct bd_rebinding audioStop;
        audioStop.name = "AUGraphStop";
        audioStop.replacement = tspk_NewAUGraphStop;
        audioStop.replaced = (void *)&tspk_OldAUGraphStop;
        
        struct bd_rebinding audioUnintialize;
        audioUnintialize.name = "AUGraphUninitialize";
        audioUnintialize.replacement = tspk_NewAUGraphUninitialize;
        audioUnintialize.replaced = (void *)&tspk_OldAUGraphUninitialize;
        
        struct bd_rebinding audioDispose;
        audioDispose.name = "DisposeAUGraph";
        audioDispose.replacement = tspk_NewDisposeAUGraph;
        audioDispose.replaced = (void *)&tspk_OldDisposeAUGraph;
        
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
                                           graph:(AUGraph)graph
                                          status:(OSStatus)status
                                   isNonsenstive:(BOOL)isNonsenstive
                                     isDowngrade:(BOOL)isDowngrade {
    return [self forwardEventWithMethodName:method
                               apiUsageType:apiUsageType
                                      graph:graph
                                     status:status
                              isNonsenstive:isNonsenstive
                               apiStoreType:TSPKAPIStoreTypeNormal
                                isDowngrade:isDowngrade];
}

+ (TSPKHandleResult *)forwardEventWithMethodName:(NSString *)method
                                    apiUsageType:(TSPKAPIUsageType)apiUsageType
                                           graph:(AUGraph)graph
                                          status:(OSStatus)status
                                   isNonsenstive:(BOOL)isNonsenstive
                                    apiStoreType:(TSPKAPIStoreType)apiStoreType
                                     isDowngrade:(BOOL)isDowngrade {
    
    return [self handleAPIAccess:method className:nil params:nil customHandleBlock:^(TSPKAPIModel * _Nonnull apiModel) {
        apiModel.apiUsageType = apiUsageType;
        apiModel.instance = nil;
        apiModel.hashTag = [NSString stringWithFormat:@"%p", graph];
        apiModel.isNonsenstive = isNonsenstive;
        apiModel.errorCode = status == noErr ? nil : [NSNumber numberWithInteger:status];
        apiModel.apiStoreType = apiStoreType;
        
        if (apiUsageType == TSPKAPIUsageTypeStart) {
            apiModel.downgradeAction = ^{
                tspk_NewAUGraphStopImp(graph, YES);
            };
        }
    }];
}

@end
