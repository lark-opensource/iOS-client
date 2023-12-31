//
//  TSPKApiStatisticsSubscriber.m
//  MT-Test
//
//  Created by admin on 2022/1/3.
//

#import "TSPKApiStatisticsSubscriber.h"
#import "TSPKThreadPool.h"
#import "TSPKConfigs.h"
#import "TSPKEvent.h"
#import "TSPKUtils.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "TSPKAppLifeCycleObserver.h"
#import "TSPKReporter.h"
#import "TSPKStatisticModel.h"
#import "TSPKStatisticConfig.h"
#import "TSPKStatisticEvent.h"
#import <PNSServiceKit/PNSKVStoreProtocol.h>
#import <PNSServiceKit/PNSRuleEngineProtocol.h>
#import <PNSServiceKit/PNSBacktraceProtocol.h>

static NSString *_Nonnull TSPKKVStoreKeyAPIStatistic = @"APIStatistic";
static NSString *_Nonnull TSPKActionTypeKey = @"action_type";

@interface TSPKCompareBacktracesResult : NSObject

@property (nonatomic) BOOL isSameBacktraces;
@property (nonatomic) NSInteger stackIndex;

@end

@implementation TSPKCompareBacktracesResult

@end

@interface TSPKApiStatisticsSubscriber()

@property(nonatomic, strong) NSMutableDictionary<NSString *,TSPKStatisticModel *> *statisticsAPIDict;
@property(nonatomic, strong) TSPKStatisticConfig *statisticConfig;
@property(nonatomic, strong) dispatch_source_t timer;
@property(nonatomic, strong) dispatch_queue_t factQueue;

@end

@implementation TSPKApiStatisticsSubscriber

- (instancetype)init
{
    self = [super init];
    if (self) {
        _factQueue = dispatch_queue_create("com.bytedance.privacykit.factQueue", DISPATCH_QUEUE_SERIAL);
        _statisticsAPIDict = [NSMutableDictionary new];
        _statisticConfig = [TSPKStatisticConfig new];
        
        NSArray *config = [[TSPKConfigs sharedConfig] apiStatisticsConfigs];
        NSDictionary *factConfig = [config firstObject];
        _statisticConfig.factTimeout = [factConfig btd_integerValueForKey:@"fact_timeout" default:30];
        _statisticConfig.factQueueSize = [factConfig btd_integerValueForKey:@"fact_queue_size" default:10];
        _statisticConfig.factParameters = [factConfig btd_arrayValueForKey:@"fact_parameter" default:@[]];
    }
    return self;
}

- (void)dealloc
{
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}
 
- (void)reportStatisticEvent:(TSPKStatisticModel *)obj {
    if (obj.count == 0) {
        return;
    }
    TSPKStatisticEvent *event = [TSPKStatisticEvent new];
    event.serviceName = @"nvwa_api_fact";
    event.metric = @{
        @"count": @(obj.count),
        @"duration": @(obj.endTime - obj.startTime)
    };
    
    NSMutableDictionary *mutableHostStates = obj.hostStates;
    [mutableHostStates removeObjectForKey:@"user_id"];
    [mutableHostStates setObject:obj.key forKey:@"api"];
    event.category = [mutableHostStates copy];
    
    event.attributes = @{
        @"start_time": @(obj.startTime),
        @"end_time": @(obj.endTime),
        @"time_series": obj.timeDifferenceArray,
        @"cert_token": obj.bpeaCertToken,
        @"last_page": obj.lastPages,
        @"stack_set": obj.deduplicationStackStringArray,
        @"stack": obj.stackIndexArray,
        @"background_time": @(obj.lastEnterBackgroundTime)
    };

    [[TSPKReporter sharedReporter] report:event];
}

- (BOOL)canHandelEvent:(TSPKEvent *)event {
    return YES;
}

- (NSError *)hanleEvent:(TSPKEvent *)event {
    if (self.statisticConfig.factTimeout == 0 && self.statisticConfig.factQueueSize == 0) {
        return nil;
    }
    
    TSPKEventData *eventCopy = event.eventData.copy;
    
    dispatch_async(self.factQueue, ^{
        NSString *targetKey = [TSPKUtils concateClassName:eventCopy.apiModel.apiClass method:eventCopy.apiModel.apiMethod joiner:@"_"];
        
        TSPKStatisticConfig *statisticConfig = self.statisticConfig;
        // get api states info
        NSDictionary *states = [self getAllStates];
        NSString *lastPage = [states btd_stringValueForKey:@"current_page"];
        eventCopy.topPageName = lastPage;
        
        NSArray *factParameters = statisticConfig.factParameters;
        
        NSMutableDictionary *hostStates = [NSMutableDictionary new];
        [states enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            for (NSString *parameter in factParameters){
                if ([key isEqualToString:parameter]) {
                    [hostStates setObject:obj forKey:key];
                }
            }
        }];
        BOOL isBackground = [[TSPKAppLifeCycleObserver sharedObserver] isAppBackground];
        [hostStates setValue:@(isBackground) forKey:@"is_background"];
        if (eventCopy.ruleEngineAction == TSPKResultActionFuse) {
            [hostStates setValue:@"fuse" forKey:TSPKActionTypeKey];
        } else if (eventCopy.ruleEngineAction == TSPKResultActionCache && !eventCopy.cacheNeedUpdate) {
            [hostStates setValue:@"cache" forKey:TSPKActionTypeKey];
        } else {
            [hostStates setValue:@"guard" forKey:TSPKActionTypeKey];
        }
        
        NSString *apiSubType = [eventCopy.apiModel.params btd_stringValueForKey:TSPKAPISubTypeKey];
        if (apiSubType) {
            [hostStates setValue:apiSubType forKey:TSPKAPISubTypeKey];
        }
        
        if (self.statisticsAPIDict[targetKey]) {
            self.statisticsAPIDict[targetKey].timeCountDown = statisticConfig.factTimeout;
        }
        // If the call interval of the api is greater than timeCountDown, report it
        if (!self.timer) {
            self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.factQueue);
            dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC));
            uint64_t interval = (uint64_t)(1 * NSEC_PER_SEC);
            dispatch_source_set_timer(self.timer, start, interval, 0);
            dispatch_source_set_event_handler(self.timer, ^{
                [self.statisticsAPIDict.copy enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, TSPKStatisticModel * _Nonnull obj, BOOL * _Nonnull stop) {
                    obj.timeCountDown--;
                    if (obj.timeCountDown <= 0) {
                        //uid change,remove all data
                        NSString *newUid = [[self getAllStates] btd_stringValueForKey:@"user_id"];
                        NSString *oldUid = [obj.hostStates btd_stringValueForKey:@"user_id"];
                        if (newUid && oldUid && ![newUid isEqualToString:oldUid]) {
                            //uid change,remove data
                            [self.statisticsAPIDict removeObjectForKey:obj.key];
                        } else {
                            [obj.hostStates setValue:@"timeout" forKey:@"reason"];
                            [self reportThenRemoveTargetKey:obj.key];
                        }
                    }
                }];
            });
            dispatch_resume(self.timer);
        }

        NSDictionary *bpeaContext = eventCopy.bpeaContext;
        NSString *certToken = [bpeaContext btd_stringValueForKey:@"certToken"];
        
        if (self.statisticsAPIDict[targetKey] == nil) {
            [self createStatisticModel:targetKey eventData:eventCopy hostStates:hostStates];
        } else {
            //compare state
            NSDictionary *targetKeyStates = self.statisticsAPIDict[targetKey].hostStates;
            if (![hostStates isEqualToDictionary:targetKeyStates]) {
                NSString *newUid = [hostStates btd_stringValueForKey:@"user_id"];
                NSString *oldUid = [targetKeyStates btd_stringValueForKey:@"user_id"];
                if (newUid && oldUid && ![newUid isEqualToString:oldUid]) {
                    //uid change,remove data
                    [self.statisticsAPIDict removeObjectForKey:targetKey];
                } else {
                    //state change,upload,then create new model
                    [targetKeyStates setValue:@"change" forKey:@"reason"];
                    [self reportThenRemoveTargetKey:targetKey];
                    [self createStatisticModel:targetKey eventData:eventCopy hostStates:hostStates];
                }
            } else {
                //state not change
                TSPKStatisticModel *model = self.statisticsAPIDict[targetKey];
                model.count++;
                NSTimeInterval timestamp = eventCopy.serverTimestamp;
                NSInteger timeDifference = [TSPKUtils convertDoubleToNSInteger:(timestamp - model.timestamp)];
                [model.timeDifferenceArray addObject:@(timeDifference)];
                model.timestamp = timestamp;
                model.endTime = [TSPKUtils convertDoubleToNSInteger:eventCopy.serverTimestamp];
                [model.lastPages addObject:eventCopy.topPageName ?: @""];
                NSArray *backtraces = eventCopy.apiModel.backtraces;
                if (backtraces) {
                    TSPKCompareBacktracesResult *result = [self compareBacktraces:model.deduplicationStackArray newBacktraces:backtraces];
                    if (result.isSameBacktraces) {
                        [model.stackIndexArray addObject:@(result.stackIndex)];
                    } else {
                        [model.deduplicationStackArray addObject:backtraces];
                        NSString *stackString = [PNS_GET_INSTANCE(PNSBacktraceProtocol) formatBacktraces:backtraces];
                        [model.deduplicationStackStringArray addObject:stackString];
                        [model.stackIndexArray addObject:@(model.deduplicationStackStringArray.count - 1)];
                    }
                } else {
                    if ([model.deduplicationStackStringArray containsObject:@""]) {
                        NSUInteger index = [model.deduplicationStackStringArray indexOfObject:@""];
                        [model.stackIndexArray addObject:@(index)];
                    } else {
                        [model.deduplicationStackStringArray addObject:@""];
                        [model.stackIndexArray addObject:@(model.deduplicationStackStringArray.count - 1)];
                    }
                }
                if (certToken) {
                    [model.bpeaCertToken addObject:certToken];
                } else {
                    [model.bpeaCertToken addObject:@""];
                }
                //if count exceed factQueueSize, upload
                if (model.count >= statisticConfig.factQueueSize) {
                    [model.hostStates setValue:@"oversize" forKey:@"reason"];
                    [self reportThenRemoveTargetKey:targetKey];
                }
            }
        }
    });
    return nil;
}

- (NSString *)uniqueId {
    return @"TSPKApiStatisticsSubscriber";
}

- (NSDictionary *)getAllStates
{
    return [PNS_GET_INSTANCE(PNSRuleEngineProtocol) contextInfo];
}

- (void)reportThenRemoveTargetKey:(NSString *)targetKey
{
    TSPKStatisticModel *targetModel = self.statisticsAPIDict[targetKey];
    [self reportStatisticEvent:targetModel];
    [self.statisticsAPIDict removeObjectForKey:targetModel.key];
}

- (void)createStatisticModel:(NSString *)targetKey eventData:(TSPKEventData *)eventData hostStates:(NSMutableDictionary *)hostStates
{
    TSPKStatisticModel *model = [TSPKStatisticModel new];
    model.lastEnterBackgroundTime = [TSPKUtils convertDoubleToNSInteger:[[TSPKAppLifeCycleObserver sharedObserver] getServerTimeLastDidEnterBackground]];
    model.key = targetKey;
    model.count = 1;
    model.timestamp = eventData.serverTimestamp;
    model.timeDifferenceArray = [[NSMutableArray alloc] init];
    model.hostStates = hostStates;
    model.startTime = [TSPKUtils convertDoubleToNSInteger:eventData.serverTimestamp];
    model.endTime = [TSPKUtils convertDoubleToNSInteger:eventData.serverTimestamp];
    model.timeCountDown = self.statisticConfig.factTimeout;
    model.lastPages = [[NSMutableArray alloc] init];
    [model.lastPages addObject:eventData.topPageName ?: @""];
    model.deduplicationStackArray = [[NSMutableArray alloc] init];
    [model.deduplicationStackArray addObject:eventData.apiModel.backtraces ?: @[]];
    model.deduplicationStackStringArray = [[NSMutableArray alloc] init];
    if (eventData.apiModel.backtraces) {
        NSString *stackIndexArray = [PNS_GET_INSTANCE(PNSBacktraceProtocol) formatBacktraces:eventData.apiModel.backtraces];
        [model.deduplicationStackStringArray addObject:stackIndexArray];
    } else {
        [model.deduplicationStackStringArray addObject:@""];
    }
    model.stackIndexArray = [[NSMutableArray alloc] init];
    [model.stackIndexArray addObject:[NSNumber numberWithUnsignedInteger:0]];
    NSDictionary *bpeaContext = eventData.bpeaContext;
    NSString *certToken = [bpeaContext btd_stringValueForKey:@"certToken"];
    model.bpeaCertToken = [[NSMutableArray alloc] init];
    [model.bpeaCertToken addObject:certToken ?: @""];
    self.statisticsAPIDict[targetKey] = model;
}

- (TSPKCompareBacktracesResult *)compareBacktraces:(NSArray *)backtracesArray newBacktraces:(NSArray *)newBacktraces
{
    TSPKCompareBacktracesResult *result = [[TSPKCompareBacktracesResult alloc] init];
    result.isSameBacktraces = NO;
    result.stackIndex = 0;
    
    for (int i = 0; i < backtracesArray.count; i++) {
        if ([PNS_GET_INSTANCE(PNSBacktraceProtocol) isSameBacktracesWithFirst:backtracesArray[i] second:newBacktraces]) {
            result.isSameBacktraces = YES;
            result.stackIndex = i;
            break;
        }
    }

    return result;
}

@end
