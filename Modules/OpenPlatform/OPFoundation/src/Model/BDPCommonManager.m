//
//  BDPCommonManager.m
//  Timor
//
//  Created by 王浩宇 on 2019/5/23.
//

#import "BDPCommonManager.h"
#import "BDPUtils.h"

@interface BDPCommonManager ()

@property (nonatomic, strong) NSMapTable <BDPUniqueID *, BDPCommon *> *commons;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end

@implementation BDPCommonManager

#pragma mark - Initialize
/*-----------------------------------------------*/
//              Initialize - 初始化相关
/*-----------------------------------------------*/
+ (instancetype)sharedManager
{
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[BDPCommonManager alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _commons = [[NSMapTable alloc] initWithKeyOptions:NSMapTableCopyIn valueOptions:NSMapTableStrongMemory capacity:5];
        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

// 外部调用方避免多线程问题
- (void)addCommon:(BDPCommon *)common uniqueID:(BDPUniqueID *)uniqueID
{
    if (common && uniqueID) {
        [_lock lock];
        [self.commons setObject:common forKey:uniqueID];
        [_lock unlock];
    }
}

- (void)removeCommonWithUniqueID:(BDPUniqueID *)uniqueID
{
    if (uniqueID) {
        [_lock lock];
        [self.commons removeObjectForKey:uniqueID];
        [_lock unlock];
    }
}

- (BDPCommon *)getCommonWithUniqueID:(BDPUniqueID *)uniqueID
{
    if (uniqueID) {
        BDPCommon *ret = nil;
        [_lock lock];
        ret = [self.commons objectForKey:uniqueID];
        [_lock unlock];
        return ret;
    }
    return nil;
}

@end
