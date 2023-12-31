//Copyright © 2021 Bytedance. All rights reserved.

#import "TSPKWebViewUtils.h"
#import "TSPKConfigs.h"
#import "TSPKLock.h"
#import "TSPKUtils.h"

@interface TSPKWebViewUtils ()

@property(nonatomic, strong, nullable) NSMutableArray *mutableCacheURLArray;
@property(nonatomic, strong) id<TSPKLock> lock;

@end

@implementation TSPKWebViewUtils

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [TSPKLockFactory getLock];
        _mutableCacheURLArray = [NSMutableArray array];
    }
    return self;
}

+ (instancetype _Nonnull)sharedUtil {
    static TSPKWebViewUtils *util;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        util = [TSPKWebViewUtils new];
    });
    return util;
}

- (void)cacheURL:(NSURL *)url {
    NSInteger maxSize = [[TSPKConfigs sharedConfig] maxURLCacheSize];
    
    [self.lock lock];
    NSInteger arraySize = self.mutableCacheURLArray.count;
    if (arraySize > maxSize) {
        [self.mutableCacheURLArray removeObjectAtIndex:0];
    }
    [self.mutableCacheURLArray addObject:[NSString stringWithFormat:@"[%.2f]{url: %@}", [TSPKUtils getRelativeTime], url]];
    [self.lock unlock];
}

- (NSArray *)getCacheURLArray {
    NSArray *result;
    [self.lock lock];
    result = self.mutableCacheURLArray.copy;
    [self.lock unlock];
    return result;
}

@end
