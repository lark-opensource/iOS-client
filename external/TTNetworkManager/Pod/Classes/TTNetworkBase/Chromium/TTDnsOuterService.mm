//
//  TTDnsOuterService.m
//  TTNetworkManager
//
//  Created by xiejin.rudy on 2020/8/9.
//

#import "TTDnsOuterService.h"
#import "TTDnsQuery.h"
#import "TTDnsResult.h"
#import <Foundation/Foundation.h>
#import "TTNetworkManagerChromium.h"
#include "components/cronet/ios/cronet_environment.h"


@implementation TTDnsOuterService

- (id)init {
    self = [super init];
    
    if (self) {
        self.dnsQueryMap = [[NSMutableDictionary alloc] init];
    }
    return self;
}


- (TTDnsResult*)ttDnsResolveWithHost:(NSString*)host
                               sdkId:(int)sdkId {
    TTDnsQuery *query = [[TTDnsQuery alloc] initWithHost:host sdkId:sdkId];
    @synchronized(self) {
        [self.dnsQueryMap setObject:query forKey:[query uuid]];
    }
    [query doQuery];
    [query await];
    return [query result];
}

- (void)handleTTDnsResultWithUUID:(NSString*)uuid
                                 host:(NSString*)host
                                  ret:(int)ret
                               source:(int)source
                          cacheSource:(int)cacheSource
                               ipList:(NSArray<NSString*>*)ipList
                         detailedInfo:(NSString*)detailedInfo {
    __block TTDnsQuery * query;
    @synchronized(self) {
        query = [self.dnsQueryMap objectForKey:uuid];
    }
    if (query) {
        TTDnsResult * result = [[TTDnsResult alloc] initWithRet:ret source:source cacheSource:cacheSource ipList:ipList detailedInfo:detailedInfo];
        [query setResult: result];
        [query resume];
        @synchronized(self) {
            [self.dnsQueryMap removeObjectForKey:uuid];
        }
    }
}

@end
