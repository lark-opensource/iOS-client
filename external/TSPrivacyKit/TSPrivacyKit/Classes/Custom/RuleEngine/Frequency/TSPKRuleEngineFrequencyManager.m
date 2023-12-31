//
//  TSPKRuleEnegineFrequencyManager.m
//  Indexer
//
//  Created by admin on 2022/2/24.
//

#import "TSPKRuleEngineFrequencyManager.h"
#import "TSPKConfigs.h"
#import "TSPKUtils.h"
#import "TSPKEvent.h"
#import "TSPKLock.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface TSPKRuleEngineFrequencyManager ()

@property(nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSMutableArray<NSNumber *> *> *storeDict;
@property (nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKRuleEngineFrequencyManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.lock = [TSPKLockFactory getLock];
        self.storeDict = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedManager {
    static TSPKRuleEngineFrequencyManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[TSPKRuleEngineFrequencyManager alloc] init];
    });
    return manager;
}

- (NSString *)uniqueId {
    return @"RuleEnegineFrequencyManager";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event {
    return YES;
}

- (TSPKHandleResult *)hanleEvent:(TSPKEvent *)event {
    NSTimeInterval currentTime = [TSPKUtils getUnixTime];
    
    [self.lock lock];
    for (NSDictionary *config in [[TSPKConfigs sharedConfig] frequencyConfigs]) {
        NSDictionary *guardRange = [config btd_dictionaryValueForKey:@"guard_range"];
        
        BOOL isTargetDataType = NO;
        NSArray *targetDataTypes = [guardRange btd_arrayValueForKey:@"data_types"];
        if ([targetDataTypes containsObject:event.eventData.apiModel.dataType]) {
            isTargetDataType = YES;
        }
        
        if ([[guardRange btd_arrayValueForKey:@"apis"] containsObject:event.eventData.apiModel.apiMethod] || isTargetDataType) {
            NSString *name = [config btd_stringValueForKey:@"name"];
            if (self.storeDict[name] == nil) {
                self.storeDict[name] = [NSMutableArray array];
            }
            // clear useless data
            [self clearUnavailableData:config name:name currentTime:currentTime];
            
            [self.storeDict[name] addObject:@(currentTime)];
        }
    }
    [self.lock unlock];
    return nil;
}

- (BOOL)isVaildWithName:(NSString *)name {
    NSTimeInterval currentTime = [TSPKUtils getUnixTime];
    
    NSDictionary *targetConfig = nil;
    
    [self.lock lock];
    
    for (NSDictionary *config in [[TSPKConfigs sharedConfig] frequencyConfigs]) {
        if ([name isEqualToString:[config btd_stringValueForKey:@"name"]]) {
            targetConfig = config;
            break;
        }
    }
    
    if (targetConfig) {
        [self clearUnavailableData:targetConfig name:name currentTime:currentTime];
        NSTimeInterval count = self.storeDict[name].count;
        [self.lock unlock];
        return count > [targetConfig[@"max_called_times"] intValue];
    }
    
    [self.lock unlock];
    return NO;
}

- (void)clearUnavailableData:(NSDictionary *)config name:(NSString *)name currentTime:(NSTimeInterval)currentTime {
    while (self.storeDict[name].count > 0 && currentTime - [self.storeDict[name][0] intValue] > [config[@"time_interval"] intValue]) {
        [self.storeDict[name] removeObjectAtIndex:0];
    }
    
    while (self.storeDict[name].count > 0 && self.storeDict[name].count > [config[@"max_store_size"] intValue]) {
        [self.storeDict[name] removeObjectAtIndex:0];
    }
}

@end
