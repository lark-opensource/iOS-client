//
//  BDImageNSCache.m
//  BDWebImage
//
//  Created by 陈奕 on 2019/9/26.
//

#import "BDImageNSCache.h"
#import "UIImage+BDWebImage.h"

@interface BDImageNSCache <KeyType, ObjectType> ()

@property (nonatomic, assign) BOOL clearMemoryOnMemoryWarning; // 是否内存低时清除所有内存缓存，默认YES
@property (nonatomic, assign) BOOL clearMemoryWhenEnteringBackground; // 是否进入后台时清除所有内存缓存，默认YES
@property (assign, nonatomic) BOOL shouldUseWeakMemoryCache; //是否使用 weak cache 优化内存缓存

@property (nonatomic, strong, nonnull) NSMapTable<KeyType, ObjectType> *weakCache; // strong-weak cache
@property (nonatomic, strong, nonnull) dispatch_semaphore_t weakCacheLock; // a lock to keep the access to `weakCache`

@end

@implementation BDImageNSCache

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit:[BDImageCacheConfig new]];
    }
    return self;
}

- (nonnull instancetype)initWithConfig:(nonnull BDImageCacheConfig *)config
{
    self = [super init];
    if (self) {
        [self commonInit:config];
    }
    return self;
}

- (void)setConfig:(BDImageCacheConfig *)config
{
    self.clearMemoryOnMemoryWarning = config.clearMemoryOnMemoryWarning;
    self.clearMemoryWhenEnteringBackground = config.clearMemoryWhenEnteringBackground;
    self.shouldUseWeakMemoryCache = config.shouldUseWeakMemoryCache;
    self.totalCostLimit = config.memorySizeLimit;
    self.countLimit = config.memoryCountLimit;
}

- (void)commonInit:(BDImageCacheConfig *)config
{
    [self setConfig:config];
    
    self.weakCache = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory
                                               valueOptions:NSPointerFunctionsWeakMemory
                                                   capacity:0];
    self.weakCacheLock = dispatch_semaphore_create(1);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveMemoryWarning:)
                                                 name:UIApplicationDidReceiveMemoryWarningNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didEnterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    if (self.clearMemoryOnMemoryWarning) {
        [super removeAllObjects];
    }
}

- (void)didEnterBackground:(NSNotification *)notification
{
    if (self.clearMemoryWhenEnteringBackground) {
        [super removeAllObjects];
    }
}

- (BOOL)containsObjectForKey:(id)key
{
    return [self objectForKey:key] != nil;
}

// `setObject:forKey:` just call this with 0 cost. Override this is enough
- (void)setObject:(id)obj forKey:(id)key cost:(NSUInteger)g
{
    [super setObject:obj forKey:key cost:g];
    if (!self.shouldUseWeakMemoryCache) {
        return;
    }
    if (key && obj) {
        // Store weak cache
        dispatch_semaphore_wait(_weakCacheLock, DISPATCH_TIME_FOREVER);
        [self.weakCache setObject:obj forKey:key];
        dispatch_semaphore_signal(_weakCacheLock);
    }
}

- (id)objectForKey:(id)key
{
    id obj = [super objectForKey:key];
    if (!self.shouldUseWeakMemoryCache) {
        return obj;
    }
    if (key && !obj) {
        // Check weak cache
        dispatch_semaphore_wait(_weakCacheLock, DISPATCH_TIME_FOREVER);
        obj = [self.weakCache objectForKey:key];
        dispatch_semaphore_signal(_weakCacheLock);
        if (obj) {
            // Sync cache
            NSUInteger cost = 0;
            if ([obj isKindOfClass:[UIImage class]]) {
                cost = [(UIImage *)obj bd_imageCost];
            }
            [super setObject:obj forKey:key cost:cost];
        }
    }
    return obj;
}

- (void)removeObjectForKey:(id)key
{
    [super removeObjectForKey:key];
    if (!self.shouldUseWeakMemoryCache) {
        return;
    }
    if (key) {
        // Remove weak cache
        dispatch_semaphore_wait(_weakCacheLock, DISPATCH_TIME_FOREVER);
        [self.weakCache removeObjectForKey:key];
        dispatch_semaphore_signal(_weakCacheLock);
    }
}

- (void)removeAllObjects
{
    [super removeAllObjects];
    if (!self.shouldUseWeakMemoryCache) {
        return;
    }
    // Manually remove should also remove weak cache
    dispatch_semaphore_wait(_weakCacheLock, DISPATCH_TIME_FOREVER);
    [self.weakCache removeAllObjects];
    dispatch_semaphore_signal(_weakCacheLock);
}

@end
