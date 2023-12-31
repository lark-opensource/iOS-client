//
//  TSPKRelationObjectModel.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/26.
//

#import "TSPKRelationObjectModel.h"

#import "TSPKUtils.h"

@interface TSPKRelationObjectModel ()

@property (nonatomic, strong) NSMutableArray<TSPKEventData *> *apiEvents;
@property (nonatomic, strong) TSPKEventData *latestActiveEvent;
@property (nonatomic, strong) TSPKEventData *latestActiveStartEvent;

@property (nonatomic) TSPKRelationObjectStatus objectStatus;
@property (nonatomic) NSTimeInterval updateTimeStamp;

@end

@implementation TSPKRelationObjectModel

- (instancetype)init
{
    if (self = [super init]) {
        _apiEvents = [NSMutableArray array];
        _objectStatus = TSPKRelationObjectStatusDefault;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    TSPKRelationObjectModel *newObject = [[[self class] allocWithZone:zone] init];
    newObject.apiEvents = [self.apiEvents copy];
    newObject.latestActiveEvent = self.latestActiveEvent;
    newObject.latestActiveStartEvent = self.latestActiveStartEvent;
    newObject.objectStatus = self.objectStatus;
    newObject.updateTimeStamp = self.updateTimeStamp;
    newObject.reportTimeStamp = self.reportTimeStamp;
    return newObject;
}

- (void)saveEventData:(TSPKEventData *)eventData
{
    // instance has been dealloc, not necessary to process coming data
    if (self.objectStatus == TSPKAPIUsageTypeDealloc) {
        return;
    }
    
    self.updateTimeStamp = [TSPKUtils getRelativeTime];
    
    switch (eventData.apiModel.apiUsageType) {
        case TSPKAPIUsageTypeStart:
        {
            [self saveStartData:eventData];
            break;
        }
            
        case TSPKAPIUsageTypeStop:
        {
            [self saveStopData:eventData];
            break;
        }
            
        case TSPKAPIUsageTypeInfo:
        {
            [self saveInfoData:eventData];
            break;
        }
            
        case TSPKAPIUsageTypeDealloc:
        {
            [self saveDeallocData:eventData];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark -
- (void)saveStartData:(TSPKEventData *)eventData
{
    [self.apiEvents addObject:eventData];
    if (self.objectStatus != TSPKAPIUsageTypeStart) {
        self.objectStatus = (TSPKRelationObjectStatus)TSPKAPIUsageTypeStart;
        self.latestActiveEvent = eventData;
        self.latestActiveStartEvent = eventData;
    }
}

- (void)saveStopData:(TSPKEventData *)eventData
{
    [self.apiEvents addObject:eventData];
    if (eventData.apiModel.errorCode != nil) {
        return;
    }
    
    if (self.objectStatus != TSPKAPIUsageTypeStop) {
        self.objectStatus = (TSPKRelationObjectStatus)TSPKAPIUsageTypeStop;
        [self.apiEvents removeAllObjects];
        self.latestActiveEvent = nil;
    }
}

- (void)saveInfoData:(TSPKEventData *)eventData
{
    [self.apiEvents addObject:eventData];
}

- (void)saveDeallocData:(TSPKEventData *)eventData
{
    [self.apiEvents addObject:eventData];
    self.objectStatus = (TSPKRelationObjectStatus)TSPKAPIUsageTypeDealloc;
    self.latestActiveEvent = eventData;
}

- (void)removeLastStartBacktrace {
    [self.apiEvents enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TSPKEventData * _Nonnull eventData, NSUInteger idx, BOOL * _Nonnull stop) {
        if (eventData.apiModel.apiUsageType == TSPKAPIUsageTypeStart) {
            eventData.apiModel.backtraces = nil;
            *stop = YES;
        }
    }];
}

#pragma mark -
- (BOOL)sameSinceLastReport {//check whether the events keep same since last report. In this case, no need to check again
    if (self.latestActiveEvent.timestamp < DBL_EPSILON) {
        return YES;
    }
    
    if (self.latestActiveEvent.timestamp < self.reportTimeStamp) {
        return YES;
    }
    return NO;
}

- (nullable TSPKEventData *)getLatestOpenEventData {
    __block TSPKEventData *result;
    
    [self.apiEvents enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TSPKEventData * _Nonnull eventData, NSUInteger idx, BOOL * _Nonnull stop) {
        TSPKAPIUsageType type = eventData.apiModel.apiUsageType;
        if (type == TSPKAPIUsageTypeStart) {
            result = eventData;
            *stop = YES;
        }
    }];

    return result;
}

- (TSPKEventData *)checkUnreleaseStartAtTime:(NSTimeInterval)timestamp condition:(TSPKDetectCondition *)condition {
    if (self.objectStatus == TSPKRelationObjectStatusDealloc) {
        return nil;
    }
    
    if (self.latestActiveEvent.timestamp < DBL_EPSILON) {
        return nil;
    }
    // detectTimestamp
    NSTimeInterval now = timestamp;
    NSTimeInterval cancelTime = now - condition.timeGapToCancelDetect;
    
    if (self.latestActiveStartEvent.timestamp > cancelTime) {
        return nil;  //cancel detect, see TSPKDetectCondition - timeGapToCancelDetect
    }
    
    NSTimeInterval validTime = now - condition.timeGapToIgnoreStatus;
    if (self.latestActiveEvent.timestamp < validTime) {
        if (self.objectStatus == TSPKRelationObjectStatusStart) {
            return self.latestActiveEvent;
        }
        
        if (self.objectStatus == TSPKRelationObjectStatusStop) {
            return nil;
        }
    }
    
    // when latest status not expected, try to search from start
    TSPKEventData *lastActiveStartEvent = nil;
    for (TSPKEventData *event in self.apiEvents) {
        if (event.timestamp > validTime) {
            break;
        }
        
        // ignore failed event
        if (event.apiModel.errorCode != nil) {
            continue;
        }
        
        // find first start event after stop event
        TSPKAPIUsageType apiType = event.apiModel.apiUsageType;
        if (apiType == TSPKAPIUsageTypeStart) {
            if (lastActiveStartEvent == nil) {
                lastActiveStartEvent = event;
            }
        } else if (apiType == TSPKAPIUsageTypeStop) {
            lastActiveStartEvent = nil;
        }
    }
    
    return lastActiveStartEvent;
}

- (NSString *)snapshotAtTime:(NSTimeInterval)timestamp condition:(TSPKDetectCondition *)condition
{
    NSString *output = @"";
    NSTimeInterval now = timestamp;
    NSTimeInterval validTime = now - condition.timeGapToIgnoreStatus;
    
    for (TSPKEventData *event in self.apiEvents) {
        BOOL shouldIgnore = event.timestamp > validTime;
        NSString *ignoreStr = shouldIgnore ? @"[Ignore]" : @"";
        NSString *errorStr = event.apiModel.errorCode == nil ? @"" : [NSString stringWithFormat:@"[error:%@]", event.apiModel.errorCode];
        NSTimeInterval seconds = now - event.timestamp;
        
        NSString *prefixStr = [NSString stringWithFormat:@"%@%@", ignoreStr, errorStr];
        if (event.apiModel.isDowngradeBehavior) {
            prefixStr = [NSString stringWithFormat:@"%@[Downgrade]", prefixStr];
        }
        
        NSString *stateStr = nil;
        BOOL isUnrelease = (self.objectStatus == TSPKRelationObjectStatusStart);
        BOOL invalidStatus = (self.objectStatus == TSPKRelationObjectStatusDefault);
        if(isUnrelease || invalidStatus){
            stateStr = [NSString stringWithFormat:@"[State:%@][TopPage:%@][Time:%.2f]", event.appStatus, event.topPageName?:@"" ,seconds];
        }else{
            stateStr = [NSString stringWithFormat:@"[State:%@][Time:%.2f]", event.appStatus, seconds];
        }
        NSString *eventString = [NSString stringWithFormat:@"%@%@%@", prefixStr, stateStr, event.apiModel.apiMethod];
        output = [output length] > 0 ? [NSString stringWithFormat:@"%@-%@", output, eventString] : eventString;
    }
    
    return output;
}

@end
