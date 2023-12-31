//
//  HMDTTMonitorTagHelper.m
//  Heimdallr-6ca2cf9f
//
//  Created by 崔晓兵 on 2/8/2022.
//

#import "HMDTTMonitorTagHelper.h"
#import <pthread/pthread.h>

static TagVerifyBlock globalTagVerifyBlock;
static NSInteger globalCurrentTag = -1;
static pthread_rwlock_t _rwlock = PTHREAD_RWLOCK_INITIALIZER;

@implementation HMDTTMonitorTagHelper

+ (void)setMonitorTagVerifyBlock:(TagVerifyBlock _Nonnull)tagVerifyBlock {
    pthread_rwlock_wrlock(&_rwlock);
    globalTagVerifyBlock = [tagVerifyBlock copy];
    pthread_rwlock_unlock(&_rwlock);
}


+ (void)setMonitorTag:(NSInteger)tag {
    NSAssert(tag > 0, @"the tag's value should be greater than zero");
    pthread_rwlock_wrlock(&_rwlock);
    globalCurrentTag = tag;
    pthread_rwlock_unlock(&_rwlock);
}


+ (NSInteger)getMonitorTag {
    pthread_rwlock_rdlock(&_rwlock);
    NSInteger currentTag = globalCurrentTag;
    pthread_rwlock_unlock(&_rwlock);
    return currentTag;
}


+ (BOOL)verifyMonitorTag:(NSInteger)tag {
    if (tag <= 0) return YES;
    pthread_rwlock_rdlock(&_rwlock);
    TagVerifyBlock verifyBlock = globalTagVerifyBlock;
    pthread_rwlock_unlock(&_rwlock);
    if (!verifyBlock) return YES;
    return verifyBlock(tag);
}

@end
