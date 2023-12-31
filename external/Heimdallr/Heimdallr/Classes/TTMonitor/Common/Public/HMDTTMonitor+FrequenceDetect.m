//
//  HMDTTMonitor+FrequenceDetect.m
//  Heimdallr-8bda3036
//
//  Created by 崔晓兵 on 6/5/2022.
//

#import "HMDTTMonitor+FrequenceDetect.h"

#include <pthread.h>

static pthread_rwlock_t lock = PTHREAD_RWLOCK_INITIALIZER;
static HMDFrequenceDetectParam *globalDetectParam = nil;

NSString * const kHMDFrequenceDetectParamDidChangeNotification = @"kHMDFrequenceDetectParamDidChangeNotification";

@implementation HMDFrequenceDetectParam

- (id)copyWithZone:(nullable NSZone *)zone {
    HMDFrequenceDetectParam *copyParam = [[HMDFrequenceDetectParam alloc] init];
    copyParam.enabled = self.enabled;
    copyParam.duration = self.duration;
    copyParam.reportInterval = self.reportInterval;
    copyParam.maxCount = self.maxCount;
    return copyParam;
}

@end


@implementation HMDTTMonitor (FrequenceDetect)

+ (void)setFrequenceDetectParam:(HMDFrequenceDetectParam *)param {
    NSAssert(param != nil, @"the param can't be nil");
    NSAssert(param.duration > 0, @"the duration must be greater than zero");
    NSAssert(param.maxCount > 0, @"the maxCount must be greater than zero");
    NSAssert(param.reportInterval > 0, @"the report interval must be greater than zero");

    if (!param || param.duration <= 0 || param.maxCount <= 0 || param.reportInterval < 0) {
        return;
    }
    
    pthread_rwlock_wrlock(&lock);
    globalDetectParam = [param copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDFrequenceDetectParamDidChangeNotification object:nil];
    pthread_rwlock_unlock(&lock);
}

+ (HMDFrequenceDetectParam *)getFrequenceDetectParam {
    HMDFrequenceDetectParam *copyParam = nil;
    pthread_rwlock_rdlock(&lock);
    if (!globalDetectParam) {
        copyParam = [[HMDFrequenceDetectParam alloc] init];
        copyParam.enabled = NO;
        copyParam.duration = 1.f;
        copyParam.maxCount = 20;
        copyParam.reportInterval = 30;
    } else {
        copyParam = [globalDetectParam copy];
    }
    pthread_rwlock_unlock(&lock);
    return copyParam;
}

@end
