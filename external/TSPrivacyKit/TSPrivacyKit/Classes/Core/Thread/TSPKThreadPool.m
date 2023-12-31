//
//  TSPKThreadPool.m
//  TSPrivacyKit
//
//  Created by PengYan on 2021/3/27.
//

#import "TSPKThreadPool.h"

@interface TSPKThreadPool ()
{
    dispatch_queue_t _workQueue;
    dispatch_queue_t _networkWorkQueue;
}

@end

@implementation TSPKThreadPool

+ (instancetype)shardPool
{
    static TSPKThreadPool *pool;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pool = [[TSPKThreadPool alloc] init];
    });
    return pool;
}

- (instancetype)init
{
    if (self = [super init]) {
        _workQueue = dispatch_queue_create("com.bytedance.privacykit.defaultQueue", DISPATCH_QUEUE_SERIAL);
        _networkWorkQueue = dispatch_queue_create("com.bytedance.privacykit.networkQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (dispatch_queue_t)workQueue
{
    return _workQueue;
}

- (dispatch_queue_t)networkWorkQueue
{
    return _networkWorkQueue;
}

- (dispatch_queue_t)lowPriorityQueue
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
}

@end
