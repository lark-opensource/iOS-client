//
//  TSPKStoreManager.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/22.
//

#import "TSPKStoreManager.h"

#import "TSPKEvent.h"
#import "TSPKStoreFactory.h"
#import "TSPKEventManager.h"
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"

@interface TSPKStoreManager ()

@property (nonatomic, strong) NSMutableDictionary *stores;//key is apiType usually

@end

@implementation TSPKStoreManager

+ (instancetype)sharedManager
{
    static TSPKStoreManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TSPKStoreManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        _stores = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)initStoreOfStoreId:(NSString *_Nonnull)storeId storeType:(TSPKStoreType)storeType
{
    id<TSPKStore> store = self.stores[storeId];
    if (store == nil) {
        store = [TSPKStoreFactory storeWithType:storeType];
        self.stores[storeId] = store;
    }
}

- (void)storeEventData:(TSPKEventData *_Nonnull)eventData
{
    NSString *storeIdentifier = eventData.storeIdentifier;
    
    id<TSPKStore> store = self.stores[storeIdentifier];
    if (store == nil) {
        store = [TSPKStoreFactory storeWithType:eventData.storeType];
        self.stores[storeIdentifier] = store;
    }
    
    [store saveEventData:eventData completion:^(NSError * _Nullable error) {
        if (error) {
            [self broadcastSaveFailedEvent:eventData];
            // ALog info
            NSString *errorMessage = [NSString stringWithFormat:@"storeEventData: error info = %@", error];
            [TSPKLogger logWithTag:TSPKLogCommonTag message:errorMessage];
        } else {
            [self broadcastSaveSuccessEvent:eventData];
        }
        // ALog info
        NSString *message = [NSString stringWithFormat:@"storeEventData: class=%@, method=%@ store %@", eventData.apiModel.apiClass, eventData.apiModel.apiMethod, error? @"fail": @"success"];
        [TSPKLogger logWithTag:TSPKLogCommonTag message:message];
    }];
}

- (id<TSPKStore>_Nonnull)getStoreOfStoreId:(NSString *_Nonnull)storeId
{
    return self.stores[storeId];
}

#pragma mark -
- (void)broadcastSaveSuccessEvent:(TSPKEventData *_Nonnull)eventData
{
    TSPKEvent *event = [TSPKEvent new];
    event.eventType = TSPKEventTypeSaveRecordComplete;
    event.eventData = eventData;
    
    [TSPKEventManager dispatchEvent:event];
}

- (void)broadcastSaveFailedEvent:(TSPKEventData *_Nonnull)eventData
{
    
}

@end
