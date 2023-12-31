//
//  TSPKDetectReleaseBadCaseTask.m
//  Indexer
//
//  Created by bytedance on 2022/2/17.
//

#import "TSPKDetectReleaseBadCaseTask.h"
#import "TSPKEventManager.h"
#import "TSPKEvent.h"
#import "TSPKRelationObjectCacheStore.h"
#import "TSPKDetectUtils.h"
#import "TSPKRuleEngineManager.h"
#import "TSPKConfigs.h"
#import "TSPKDelayDetectSchduler.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKReleaseAPIBizInfoSubscriber.h"
#import "TSPKUtils.h"
#import <PNSServiceKit/PNSBacktraceProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>
#import "TSPKBacktraceStore.h"
#import "TSPKMediaNotificationObserver.h"
#import <TSPrivacyKit/TSPKSignalManager+public.h>

@interface TSPKDetectReleaseBadCaseTask () <TSPKDelayDetectDelegate>

@property (nonatomic, assign) NSInteger detectTime;
@property (nonatomic, assign) NSInteger remainDetectTime;
@property (nonatomic, strong) TSPKDelayDetectSchduler *delayScheduler;

@property (nonatomic, copy) NSString *delayCloseInstanceAddress;
@property (nonatomic, assign) NSTimeInterval timeDelay;
@property (nonatomic, assign) NSTimeInterval firstDetectTimestamp;
@property (nonatomic, copy) NSString *anchorPage;
@property (nonatomic, copy) NSDictionary *params;

@end

@implementation TSPKDetectReleaseBadCaseTask

- (void)setup {
    [super setup];
    
    self.ignoreSameReport = YES;
}

- (void)decodeParams:(NSDictionary * _Nonnull)params
{
    [super decodeParams:params];
    
    self.params = params.copy;
    self.detectTime = MAX(1, [params[@"detectTime"] integerValue]);
    self.timeDelay = MAX(2, [params[@"timeDelay"] doubleValue]);
    self.anchorPage = params[@"pageClassName"];
    BOOL isAnchorPageCheck = NO;
    
    NSString *pageStatus = (NSString*)params[@"pageStatus"];
    if ([pageStatus isEqualToString:@"Appear"]) {
        isAnchorPageCheck = params[@"anchorPageCheck"] != nil ? [params[@"anchorPageCheck"] boolValue] : YES;
    } else if ([pageStatus isEqualToString:@"Disappear"]) {
        isAnchorPageCheck = NO;
    }
        
    if (self.detectTime > 1) {
        TSPKDelayDetectModel *delayDetectModel = [TSPKDelayDetectModel new];
        delayDetectModel.detectTimeDelay = self.timeDelay;
        delayDetectModel.isAnchorPageCheck = isAnchorPageCheck;
        delayDetectModel.isCancelPrevDetectWhenStartNewDetect = YES;
        
        self.delayScheduler = [[TSPKDelayDetectSchduler alloc] initWithDelayDetectModel:delayDetectModel delegate:self];
    }
}

- (void)executeWithScheduleTime:(NSTimeInterval)scheduleTime {
    self.firstDetectTimestamp = [TSPKUtils getRelativeTime];
    self.remainDetectTime = self.detectTime - 1;
    [super executeWithScheduleTime:scheduleTime];
}

- (void)repeatExecute {
    if (self.remainDetectTime > 0) {
        self.remainDetectTime -= 1;
        // repeat detect will only focus on one instance
        NSTimeInterval schedlueTimeStamp = [TSPKUtils getRelativeTime];
        [super executeWithInstanceAddressAndScheduleTime:self.delayCloseInstanceAddress scheduleTime:schedlueTimeStamp];
    }
}

- (void)handleDetectResult:(TSPKDetectResult *)result
           detectTimeStamp:(NSTimeInterval)detectTimeStamp
                     store:(id<TSPKStore>)store
                      info:(NSDictionary *)dict  {
    [super handleDetectResult:result detectTimeStamp:detectTimeStamp store:store info:dict];
    
    [self notifyExecuteReleaseDetect:result];
    
    BOOL isDelayCloseEvent = result.isRecordStopped && ![self isFirstDetect];
    BOOL isNotCloseEvent = !result.isRecordStopped && [self isFinalDetect];
    
    if (isDelayCloseEvent || isNotCloseEvent) {
        NSTimeInterval lastCleanTime = 0;
        if ([store isKindOfClass:[TSPKRelationObjectCacheStore class]]) {
            TSPKRelationObjectCacheStore *objectStore = (TSPKRelationObjectCacheStore *)store;
            // update report time
            [objectStore updateReportTime:detectTimeStamp];
            lastCleanTime = [objectStore getCleanTime];
        }
        
        TSPKEventData *eventData;
        if (isDelayCloseEvent) {
            eventData = [TSPKDetectUtils createSnapshotWithDataDict:dict
                                                        atTimeStamp:detectTimeStamp
                                                      lastCleanTime:lastCleanTime
                                                        inCondition:self.detectEvent.condition instanceAddress:self.delayCloseInstanceAddress];
        } else if (isNotCloseEvent) {
            eventData = [TSPKDetectUtils createSnapshotWithDataDict:dict
                                                        atTimeStamp:detectTimeStamp
                                                      lastCleanTime:lastCleanTime
                                                        inCondition:self.detectEvent.condition];
        }
        
        if (eventData != nil) {
            eventData.isReleased = result.isRecordStopped;
            eventData.unreleaseAddress = result.instanceAddress;
            [self addExtraInfoToEventData:eventData isDelayColse:isDelayCloseEvent];
            [self markRuleInfoToEventData:eventData];
            [self notifyBadcaseDetected:eventData];
        }
        
        [self markTaskFinish];
    } else if (!result.isRecordStopped && ![self isFinalDetect]) {
        // need to repeat detect
        self.delayCloseInstanceAddress = result.instanceAddress;
        [self.delayScheduler startDelayDetect];
    } else {
        [self markTaskFinish];
    }
}

- (void)notifyBadcaseDetected:(TSPKEventData *_Nonnull)eventData
{
    if (eventData.isDelayClosed) {
        [eventData.warningTypes addObject:TSPKWarningTypeDelayReleaseCheck];
    } else {
        [eventData.warningTypes addObject:TSPKWarningTypeUnReleaseCheck];
    }
    
    TSPKAPIModel *apiModel = eventData.apiModel;
    NSString *permissionType = apiModel.dataType;
    NSString *content = @"Guard detect unreleased"; // do not change it
    [TSPKSignalManager addSignalWithType:TSPKSignalTypeGuard
                          permissionType:permissionType
                                 content:content
                               extraInfo:@{@"instance": apiModel.hashTag ?:@""}];
    
    TSPKEvent *event = [TSPKEvent new];
    event.eventType = TSPKEventTypeDetectBadCase;
    event.eventData = eventData;
    [TSPKEventManager dispatchEvent:event];
}

- (void)markRuleInfoToEventData:(TSPKEventData *_Nonnull)eventData
{
    TSPKSceneRuleModel *ruleModel = self.detectEvent.detectPlanModel.ruleModel;
    eventData.matchedRuleId = ruleModel.ruleId;
    eventData.matchedRuleName = ruleModel.ruleName;
    eventData.isDelayClosed = !([self isFinalDetect] && !eventData.isReleased);
    eventData.matchedRuleType = ruleModel.type;
    eventData.matchedRuleParams = ruleModel.params.copy;
    
    if (ruleModel.params[@"isGrayScale"]) {
        eventData.isGrayScaleRule = [ruleModel.params[@"isGrayScale"] boolValue];
    }
    
    [eventData addReleaseContextInfoWithEventData:self.detectEvent.eventData];
    
    eventData.detectTime = self.detectTime - self.remainDetectTime;
    eventData.timeDelay = (NSInteger)self.timeDelay;
    eventData.totalDetectTime = self.detectTime;
    
    // merge backtraces
    NSTimeInterval timestamp = eventData.timestamp;
    NSString *pipelineType = eventData.apiModel.pipelineType;
    BOOL isMultipleAsyncStackTraceEnabled = [PNS_GET_INSTANCE(PNSBacktraceProtocol) isMultipleAsyncStackTraceEnabled];
    if (!isMultipleAsyncStackTraceEnabled && [[TSPKConfigs sharedConfig] enableMergeCustomAndSystemBacktraces]) {
        if (pipelineType.length > 0) {
            NSArray *customCallBacktraces = [[TSPKBacktraceStore shared] findMatchedBacktraceWithPipelineType:eventData.apiModel.pipelineType beforeTimestamp:timestamp];
            NSArray *systemCallBacktraces = eventData.apiModel.backtraces;
            if (customCallBacktraces.count > 0 && systemCallBacktraces.count > 0) {
                eventData.apiModel.backtraces = [PNS_GET_INSTANCE(PNSBacktraceProtocol) mergeBacktracesWithFirst:systemCallBacktraces second:customCallBacktraces];
            }
        }
    }
}

- (void)addExtraInfoToEventData:(TSPKEventData *_Nonnull)eventData isDelayColse:(BOOL)isDelayColse {
    NSString *apiType = eventData.apiModel.pipelineType;
    if (apiType.length == 0) {
        return;
    }

    NSMutableDictionary *mutableExtraInfoDic = [NSMutableDictionary dictionary];
    if (eventData.extraInfo) {
        mutableExtraInfoDic[@"PairClose"] = eventData.extraInfo;
    }
    
    [self.params enumerateKeysAndObjectsUsingBlock:^(NSString *_Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        mutableExtraInfoDic[key] = obj;
    }];
    
    // add check timestamp
    mutableExtraInfoDic[@"CheckTimestamp"] = @(self.firstDetectTimestamp);
    
    if (isDelayColse) {
        mutableExtraInfoDic[@"SystemCloseTimestamp"] = @(eventData.timestamp);
    }
    
    
    NSString *dataType = eventData.apiModel.dataType;
    if (dataType.length > 0) {
        // add biz call timestamp
        NSDictionary *bizInfo = [[TSPKReleaseAPIBizInfoSubscriber sharedInstance] getTimestampInfoWithDataType:dataType];
        if (bizInfo) {
            [mutableExtraInfoDic addEntriesFromDictionary:bizInfo];
        }
        // add media info
        NSDictionary *mediaInfo = [TSPKMediaNotificationObserver getInfoWithDataType:dataType];
        if (mediaInfo) {
            [mutableExtraInfoDic addEntriesFromDictionary:mediaInfo];
        }
    }
    
    eventData.extraInfoDic = mutableExtraInfoDic.copy;
}

- (void)notifyExecuteReleaseDetect:(TSPKDetectResult *)result
{
    TSPKSceneRuleModel *ruleModel = self.detectEvent.detectPlanModel.ruleModel;
    
    TSPKEvent *event = [TSPKEvent new];
    event.eventType = TSPKEventTypeExecuteReleaseDetect;
    NSMutableDictionary *mutableParams = @{
        @"type": @"detectType",
        @"isRelease": @(result.isRecordStopped),
        @"method": self.detectEvent.detectPlanModel.interestMethodType
    }.mutableCopy;
    
    if (!result.isRecordStopped) {
        mutableParams[@"address"] = result.instanceAddress;
    }
    
    if (ruleModel) {
        mutableParams[@"ruleId"] = @(ruleModel.ruleId);
    }
    
    mutableParams[@"detectNO"] = @(self.detectTime - self.remainDetectTime);
    if (self.remainDetectTime == 0) {
        mutableParams[@"isFinalDetect"] = @"YES";
    }
    
    [self.detectEvent.eventData addReleaseContextInfoToDic:mutableParams];
    
    NSDictionary *params = mutableParams.copy;
    event.params = params;
    
    [TSPKEventManager dispatchEvent:event];
    
    NSString *permissionType = self.detectEvent.detectPlanModel.dataType;
    if (permissionType.length > 0) {
        [TSPKSignalManager addSignalWithType:TSPKSignalTypeGuard permissionType:permissionType content:@"" extraInfo:params];
    }
}

#pragma mark - TSPKDelayDetectDelegate

- (void)executeDetectWithActualTimeGap:(NSTimeInterval)actualTimeGap {
    [self repeatExecute];
}

- (nullable NSString *)getComparePage {
    return self.anchorPage;
}

#pragma mark - other

- (BOOL)isFirstDetect {
    return self.remainDetectTime == (self.detectTime - 1);
}

- (BOOL)isFinalDetect {
    return self.remainDetectTime == 0;
}

@end
