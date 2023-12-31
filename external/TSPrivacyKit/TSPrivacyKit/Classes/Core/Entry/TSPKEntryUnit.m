//
//  TSPKEntryUnit.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/19.
//

#import "TSPKEntryUnit.h"
#import "TSPKEvent.h"
#import "TSPKEventData.h"
#import "TSPKUtils.h"
#import "TSPKEventManager.h"
#import "TSPKStoreManager.h"
#import "TSPKEntryManager.h"
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKThreadPool.h"

@implementation TSPKEntryUnitModel

@end

@interface TSPKEntryUnit ()

@property (nonatomic) BOOL entryInit;
@property (nonatomic) BOOL entryEnable;
@property (nonatomic, strong) TSPKEntryUnitModel *model;

@end

@implementation TSPKEntryUnit

- (instancetype)initWithModel:(TSPKEntryUnitModel *)model
{
    if (self = [super init]) {
        _model = model;
    }
    return self;
}

- (void)setEnable:(BOOL)enable
{
    self.entryEnable = enable;
    
    if (enable && !self.entryInit) { // one entry type is only allowed to init once
        self.entryInit = YES;
        !self.model.initAction ?: self.model.initAction();
    }
}

- (TSPKEventData *)createEventDataWithModel:(TSPKAPIModel *)model {
    TSPKEventData *eventData = [TSPKEventData new];
    eventData.apiModel = model;
    eventData.storeIdentifier = [self storeIdentifierForModel:model];
    eventData.storeType = self.model.storeType;
    [TSPKUtils exectuteOnMainThread:^{
        eventData.topPageName = [TSPKUtils topVCName];
        eventData.appStatus = [TSPKUtils appStatusString];
    }];
    eventData.bpeaContext = [self parseBPEAContext];
    eventData.uuid = eventData.bpeaContext[@"uuid"] ?: [NSUUID UUID].UUIDString;
    
    return eventData;
}

- (TSPKHandleResult *)handleAccessEntry:(TSPKAPIModel *)model {
    TSPKEventData *eventData = [self createEventDataWithModel:model];
    
    if (model.apiStoreType != TSPKAPIStoreTypeOnlyStore) {
        TSPKHandleResult *result = [self broadcastWithEventType:TSPKEventTypeAccessEntryHandle event:eventData];
        eventData.ruleEngineResult = result.returnValue;
        eventData.ruleEngineAction = result.action;
        eventData.cacheNeedUpdate = result.cacheNeedUpdate;
        [self broadcastWithEventType:TSPKEventTypeAccessEntryResult event:eventData];
        
        if (result.action) {
            return result;
        }
    }
    
    // store API call, if success, boardcast a save success event
    if (model.apiStoreType != TSPKAPIStoreTypeIgnoreStore) {
        [self saveAccessEntry:eventData];
    }
    
    return nil;
}

#pragma mark -
- (TSPKHandleResult *)broadcastWithEventType:(TSPKEventType)eventType
                                       event:(TSPKEventData *)eventData
{
    TSPKEvent *event = [TSPKEvent new];
    event.eventType = eventType;
    event.eventData = eventData;
    return [TSPKEventManager dispatchEvent:event];
}

- (void)saveAccessEntry:(TSPKEventData *)eventData
{
    if (eventData.storeType == TSPKStoreTypeNone) {
        return;
    }
    
    [[TSPKStoreManager sharedManager] storeEventData:eventData];
}

- (NSString *)storeIdentifierForModel:(TSPKAPIModel *)model
{
    return model.pipelineType;
}

- (NSDictionary *)parseBPEAContext
{
    id bpea_obj = [NSThread currentThread].threadDictionary[TSPKBPEAInfoKey];
    // clean
    if (bpea_obj) {
        [NSThread currentThread].threadDictionary[TSPKBPEAInfoKey] = nil;
    }
    
    if ([bpea_obj isKindOfClass:[NSDictionary class]]) {
        return (NSDictionary *)bpea_obj;
    }
    return nil;
}

@end
