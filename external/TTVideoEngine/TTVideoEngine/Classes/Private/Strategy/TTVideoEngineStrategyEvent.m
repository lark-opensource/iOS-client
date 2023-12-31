//
//  TTVideoEngineStrategyEvent.m
//  TTVideoEngine
//
//  Created by 黄清 on 2021/10/25.
//

#import "TTVideoEngineStrategyEvent.h"
#import "TTVideoEngineStrategy.h"
#import <VCPreloadStrategy/VCVodStrategyManager.h>
#import "TTVideoEngineUtilPrivate.h""

NSString * const kTTVideoEngineStrategyLogKey_PlayTaskControl = @"st_play_task_op";
NSString * const kTTVideoEngineStrategyLogKey_Preload = @"st_preload";
NSString * const kTTVideoEngineStrategyLogKey_BufferDuration = @"st_buf_dur";
NSString * const kTTVideoEngineStrategyLogKey_PreloadPersonalized = @"st_preload_personalized";
NSString * const kTTVideoEngineStrategyLogKey_AdaptiveRange = @"st_adaptive_range";
NSString * const kTTVideoEngineStrategyLogKey_RemainingBufferDuration = @"st_remaining_buf_dur";
NSString * const kTTVideoEngineStrategyLogKey_PreloadFinishedTime = @"st_preload_finished_time";
NSString * const kTTVideoEngineStrategyLogKey_BandwidthRange = @"st_band_range";
NSString * const kTTVideoEngineStrategyLogKey_CommonEventLog = @"st_common";

static NSString * const s_pause = @"pause";
static NSString * const s_resume = @"resume";
static NSString * const s_range = @"range";
static NSString * const s_range_dur = @"range_dur";
static NSString * const s_seeklabel = @"seek_label";

static NSString * const s_StartupBufferDuration = @"startup_buf_dur";
static NSString * const s_ReBufferDurationInitial = @"rebuf_dur_init";
static NSString * const s_PlayBufferDiffCount = @"diff_ret_count";

static NSString * const s_PreloadPersonalizedOption = @"preload_personalized_option";
static NSString * const s_WatchDurationLabel = @"watch_duration_label";
static NSString * const s_StallLabel = @"stall_label";
static NSString * const s_FirstFrameLabel = @"first_frame_label";

static NSString * const s_AdaptiveRangeEnabled = @"enabled";
static NSString * const s_AdaptiveRangeBufferLog = @"buffer_log";

static NSString * const s_CurrentBandwidth = @"current_bandwidth";
static NSString * const s_BandBitrateRatio = @"band_bitrate_ratio";

static NSString * const s_ModuleActivated = @"module_activated";

@interface _TTVideoTrackDataCounter : NSObject
@property (nonatomic, assign) NSInteger cnt;

///
/// Method
///
- (void)increase;
- (void)decrease;
- (void)reset;
- (NSNumber *)getCount;
@end

@implementation _TTVideoTrackDataCounter

- (void)increase {
    _cnt++;
}

- (void)decrease {
    _cnt--;
}

- (void)reset {
    _cnt = 0;
}

- (NSNumber *)getCount {
    return @(_cnt);
}

@end

@interface TTVideoEngineStrategyEvent() {
    NSMutableDictionary<NSString*, NSMutableDictionary<NSString*, id>*> *_vidDict;
    NSMutableDictionary<NSString*, id> *_noVidDict;
}

@end

@implementation TTVideoEngineStrategyEvent

- (instancetype)init {
    if (self = [super init]) {
        _vidDict = [NSMutableDictionary dictionary];
        _noVidDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)event:(NSString *)videoId
        event:(NSInteger)key
        value:(NSInteger)value
         info:(nullable NSString *)logInfo {
    NSMutableDictionary<NSString*, id> *eventDict;
    @synchronized (self) {
         eventDict = [self addDictIfAbsent:_vidDict ForKey:videoId];
    }
    switch (key) {
        case VCVodStrategyEventPlayTaskOperate: {
            NSMutableDictionary<NSString *, id> *onePlayDict;
            @synchronized (self) {
                if (![eventDict objectForKey:kTTVideoEngineStrategyLogKey_PlayTaskControl]) {
                    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:@{
                        s_pause: [_TTVideoTrackDataCounter new],
                        s_resume:[_TTVideoTrackDataCounter new],
                        s_range: [_TTVideoTrackDataCounter new],
                    }];
                    [eventDict setObject:dict forKey:kTTVideoEngineStrategyLogKey_PlayTaskControl];
                }
                onePlayDict = eventDict[kTTVideoEngineStrategyLogKey_PlayTaskControl];
            
                switch (value) {
                    case VCVodStrategyPlayTaskOperatePause:
                        [[onePlayDict objectForKey:s_pause] increase];
                        break;
                    case VCVodStrategyPlayTaskOperateResume:
                        [[onePlayDict objectForKey:s_resume] increase];
                        break;
                    case VCVodStrategyPlayTaskOperateRange:
                        [[onePlayDict objectForKey:s_range] increase];
                        break;
                    case VCVodStrategyPlayTaskOperateRangeDuration: {
                        NSData *jsonData = [logInfo dataUsingEncoding:NSUTF8StringEncoding];
                        id logData = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                     options:0
                                                                       error:nil];
                        [onePlayDict setValue:logData forKey:s_range_dur];
                    } break;
                    case VCVodStrategyPlayTaskOperateSeekLabel:
                        [onePlayDict setObject:logInfo forKey:s_seeklabel];
                        break;

                    default:
                        break;
                }
            }
        } break;

        case VCVodStrategyEventPreloadSwitch: {
            @synchronized (self) {
                if (logInfo != nil) {
                    [_noVidDict setObject:@{@"name": logInfo}
                                   forKey:kTTVideoEngineStrategyLogKey_Preload];
                }
            }
        } break;
            
        case VCVodStrategyEventReBufferDurationInitial: {
            @synchronized (self) {
                [[self addDictIfAbsent:eventDict
                                ForKey:kTTVideoEngineStrategyLogKey_BufferDuration]
                 setObject:@(value)
                 forKey:s_ReBufferDurationInitial];
            }
        } break;

        case VCVodStrategyEventStartupDuration: {
            @synchronized (self) {
                [[self addDictIfAbsent:eventDict
                                ForKey:kTTVideoEngineStrategyLogKey_BufferDuration]
                 setObject:@(value)
                 forKey:s_StartupBufferDuration];
            }
        } break;

        case VCVodStrategyEventPlayBufferDiffResult: {
            @synchronized (self) {
                NSMutableDictionary *bufDurDict =
                [self addDictIfAbsent:eventDict
                               ForKey:kTTVideoEngineStrategyLogKey_BufferDuration];
                if (bufDurDict[s_PlayBufferDiffCount] == nil) {
                    [bufDurDict setObject:[_TTVideoTrackDataCounter new]
                                   forKey:s_PlayBufferDiffCount];
                }
                [bufDurDict[s_PlayBufferDiffCount] increase];
            }
        } break;

        case VCVodStrategyEventPreloadPersonalizedOption: {
            @synchronized (self) {
                [[self addDictIfAbsent:eventDict
                                ForKey:kTTVideoEngineStrategyLogKey_PreloadPersonalized]
                 setObject:@(value) forKey:s_PreloadPersonalizedOption];
            }
        } break;

        case VCVodStrategyEventWatchDurationLabel: {
            @synchronized (self) {
                [[self addDictIfAbsent:eventDict
                                ForKey:kTTVideoEngineStrategyLogKey_PreloadPersonalized]
                 setObject:@(value) forKey:s_WatchDurationLabel];
            }
        } break;

        case VCVodStrategyEventStallLabel: {
            @synchronized (self) {
                [[self addDictIfAbsent:eventDict
                                ForKey:kTTVideoEngineStrategyLogKey_PreloadPersonalized]
                 setObject:@(value) forKey:s_StallLabel];
            }
        } break;

        case VCVodStrategyEventFirstFrameLabel: {
            @synchronized (self) {
                [[self addDictIfAbsent:eventDict
                                ForKey:kTTVideoEngineStrategyLogKey_PreloadPersonalized]
                 setObject:@(value) forKey:s_FirstFrameLabel];
            }
        } break;

        case VCVodStrategyEventAdaptiveRangeEnabled: {
            @synchronized (self) {
                [[self addDictIfAbsent:eventDict
                                ForKey:kTTVideoEngineStrategyLogKey_AdaptiveRange]
                 setObject:@(value) forKey:s_AdaptiveRangeEnabled];
            }
        } break;

        case VCVodStrategyEventAdaptiveRangeBuffer: {
            @synchronized (self) {
                NSData *jsonData = [logInfo dataUsingEncoding:NSUTF8StringEncoding];
                id logData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
                [[self addDictIfAbsent:eventDict
                                ForKey:kTTVideoEngineStrategyLogKey_AdaptiveRange]
                 setValue:logData forKey:s_AdaptiveRangeBufferLog];
            }
        } break;

        case VCVodStrategyEventRemainingBufferDurationAtStop: {
            @synchronized (self) {
                [eventDict setObject:@(value)
                              forKey:kTTVideoEngineStrategyLogKey_RemainingBufferDuration];
            }
        } break;

        case VCVodStrategyEventPlayRelatedPreloadFinished: {
            @synchronized (self) {
                [eventDict setObject:@(logInfo.longLongValue)
                              forKey:kTTVideoEngineStrategyLogKey_PreloadFinishedTime];
            }
        } break;

        case VCVodStrategyEventPlayerRangeDetermined: {
            @synchronized (self) {
                NSMutableDictionary *bandwidthRangeDict =
                [self addDictIfAbsent:eventDict
                               ForKey:kTTVideoEngineStrategyLogKey_BandwidthRange];
                [bandwidthRangeDict setObject:@(value) forKey:s_CurrentBandwidth];
                [bandwidthRangeDict setObject:@([logInfo floatValue]) forKey:s_BandBitrateRatio];
            }
        } break;

        case VCVodStrategyEventModuleActivated : {
            @synchronized (self) {
                [_noVidDict setObject:@{s_ModuleActivated: @(value)}
                               forKey:kTTVideoEngineStrategyLogKey_CommonEventLog];
            }
        } break;
        default:
            break;
    }
}

- (NSDictionary *)getLogDataAndPopCache:(NSString *)videoId {
    NSDictionary *retDict = [self getLogData:videoId];
    [self removeLogData:videoId];
    return retDict;
}

- (nullable NSDictionary *)getLogData:(NSString *)videoId forKey:(NSString *)key {
    if ([key isEqualToString:kTTVideoEngineStrategyLogKey_PlayTaskControl]) {
        NSDictionary<NSString *, id> *onePlayDict = nil;
        @synchronized (self) {
            onePlayDict = [[_vidDict objectForKey:videoId]
                           objectForKey:kTTVideoEngineStrategyLogKey_PlayTaskControl];
            if (onePlayDict) {
                return [self convertCounterDict:onePlayDict];
            }
        }
    } else if ([key isEqualToString:kTTVideoEngineStrategyLogKey_BufferDuration]) {
        return [[_vidDict objectForKey:videoId]
                objectForKey:kTTVideoEngineStrategyLogKey_BufferDuration];
    } else if ([key isEqualToString:kTTVideoEngineStrategyLogKey_BandwidthRange]) {
        return [[_vidDict objectForKey:videoId]
                objectForKey:kTTVideoEngineStrategyLogKey_BandwidthRange];
    }
    return nil;
}

- (NSDictionary *)getLogData:(NSString *)videoId {
    NSMutableDictionary *retDict = [NSMutableDictionary dictionary];
    @synchronized (self) {
        NSDictionary *dict = _vidDict[videoId];
        if (dict != nil) {
            [retDict addEntriesFromDictionary:[self convertCounterDict:dict]];
        }
        [retDict addEntriesFromDictionary:_noVidDict];
        
        TTVideoEngineLog(@"eventlog = %@", retDict);
    }
    return retDict.copy;
}

- (NSDictionary *)getLogDataByTraceId:(NSString *)traceId {
    NSDictionary *retDict;
    NSString *fromST = [[TTVideoEngineStrategy.helper manager] getEventLog:traceId];
    NSData *data = [fromST dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    retDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return retDict.copy;
}

- (void)removeLogData:(NSString *)videoId {
    @synchronized (self) {
        [_vidDict removeObjectForKey:videoId];
    }
}

- (void)removeLogDataByTraceId:(NSString *)traceId {
    @synchronized (self) {
        [[TTVideoEngineStrategy.helper manager] removeLogData:traceId];
    }
}
// private methods

- (NSDictionary *)convertCounterDict:(NSDictionary*)dict {
    NSMutableDictionary *retDict = [NSMutableDictionary dictionaryWithCapacity:dict.count];
    [dict enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
        if ([value isKindOfClass:[_TTVideoTrackDataCounter class]]) {
            retDict[key] = [value getCount];
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            retDict[key] = [self convertCounterDict:value];
        } else {
            retDict[key] = value;
        }
    }];
    return retDict;
}

- (NSMutableDictionary*)addDictIfAbsent:(NSMutableDictionary*)dict ForKey:(NSString*)key {
    if (dict[key] == nil) {
        dict[key] = NSMutableDictionary.dictionary;
    }
    return dict[key];
}

@end
