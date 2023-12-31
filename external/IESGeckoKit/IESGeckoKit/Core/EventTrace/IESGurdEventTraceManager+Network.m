//
//  IESGurdEventTraceManager+Network.m
//  BDAssert
//
//  Created by 陈煜钏 on 2020/7/28.
//

#import "IESGurdEventTraceManager+Network.h"
#import "IESGurdEventTraceManager+Private.h"
#import "IESGeckoDefines+Private.h"

#import <pthread/pthread.h>

@implementation IESGurdTraceNetworkInfo

+ (instancetype)infoWithMethod:(NSString *)method
                     URLString:(NSString *)URLString
                        params:(NSDictionary *)params
{
    IESGurdTraceNetworkInfo *networkInfo = [[self alloc] init];
    networkInfo.method = method;
    networkInfo.URLString = URLString;
    networkInfo.params = params;
    return networkInfo;
}

@end

static pthread_mutex_t networkLock = PTHREAD_MUTEX_INITIALIZER;

@implementation IESGurdEventTraceManager (Network)

+ (void)traceNetworkWithInfo:(IESGurdTraceNetworkInfo *)networkInfo
{
    if (!self.isEnabled || !networkInfo) {
        return;
    }
    
    GURD_MUTEX_LOCK(networkLock);
    
    NSMutableArray<IESGurdTraceNetworkInfo *> *networkInfosArray = [self sharedManager].networkInfosArray;
    if (!networkInfosArray) {
        networkInfosArray = [NSMutableArray array];
        [self sharedManager].networkInfosArray = networkInfosArray;
    }
    [networkInfosArray addObject:networkInfo];
}

+ (NSArray<IESGurdTraceNetworkInfo *> *)allNetworkInfos
{
    GURD_MUTEX_LOCK(networkLock);
    
    return [[self sharedManager].networkInfosArray copy] ? : @[];
}

@end
