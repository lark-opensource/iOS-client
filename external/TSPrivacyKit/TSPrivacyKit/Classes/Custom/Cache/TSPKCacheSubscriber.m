//
//  TSPKCacheSubcriber.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/13.
//

#import "TSPKCacheSubscriber.h"
#import "TSPKCacheEnv.h"
#import "TSPKUtils.h"
#import "TSPKEvent.h"
#import "TSPKReporter.h"
#import "TSPKUploadEvent.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <PNSServiceKit/PNSBacktraceProtocol.h>

@implementation TSPKCacheSubscriber

- (NSString *)uniqueId {
    return @"TSPKCacheSubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *)event {
    return YES;
}

- (TSPKHandleResult *)hanleEvent:(TSPKEvent *)event {
    NSString *api = [TSPKUtils concateClassName:event.eventData.apiModel.apiClass method:event.eventData.apiModel.apiMethod];
    
    if (![[TSPKCacheEnv shareEnv] containsProcessor:api]) {
        return nil;
    }
    
    TSPKHandleResult *result = [TSPKHandleResult new];
    result.action = TSPKResultActionCache;
    result.cacheNeedUpdate = [[TSPKCacheEnv shareEnv] needUpdate:api];
    return result;
}

@end
