//
//  BDABKeychainStorage.m
//  BDABTestSDK
//
//  Created by July22 on 2019/2/25.
//

#import "BDABKeychainStorage.h"

static long
bd_dispatch_sync_wait(dispatch_queue_t queue, dispatch_block_t block, NSTimeInterval timeout_seconds) {
    if (block == nil) return 0;
    
    if (timeout_seconds <= 0) {
        timeout_seconds = 0.01;
    }
    dispatch_block_t task_block = dispatch_block_create_with_qos_class(DISPATCH_BLOCK_INHERIT_QOS_CLASS, QOS_CLASS_USER_INITIATED, -8, block);
    dispatch_async(queue, task_block);
    return dispatch_block_wait(task_block, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout_seconds * NSEC_PER_SEC)));
}

@interface BDABKeychainStorage ()

@property(nonatomic, copy) NSString *serviceName;
@property (nonatomic, assign) BOOL useUserDefaultCache;
@property (nonatomic, strong) dispatch_queue_t abQueue;
@property (nonatomic, strong) id result;

@end

@implementation BDABKeychainStorage

- (instancetype)initWithServiceName:(NSString *)serviceName useUserDefaultCache:(BOOL)useUserDefaultCache
{
    if (self = [super init]) {
        _serviceName = serviceName;
        _useUserDefaultCache = useUserDefaultCache;
        _abQueue = dispatch_queue_create("com.bytedance.abtest", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (nullable id)objectForKey:(NSString *)key
{
    __block id result = nil;
    bd_dispatch_sync_wait(self.abQueue, ^{
        [self doObjectForKey:key];
        result = self.result;
    }, 1.0);
    return result;
}

- (void)doObjectForKey:(NSString *)key
{
    self.result = nil;
    if (key.length == 0) return;
    
    if (self.useUserDefaultCache) {
        id res = [[NSUserDefaults standardUserDefaults] objectForKey:key];
        if (res) {
            self.result = res;
            return;
        }
    }
    
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithCapacity:6];
    [query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
    [query setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    [query setObject:self.serviceName forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [query setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnData)];
    [query setObject:(__bridge id)(kSecMatchLimitOne) forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
    CFTypeRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (status != errSecSuccess) {
        if (result) {
            CFRelease(result);
        }
        return;
    }
    
    NSData *data = [NSData dataWithData:(__bridge NSData *)(result)];
    if (result) {
        CFRelease(result);
    }
    
    id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    if (self.useUserDefaultCache) {
        [[NSUserDefaults standardUserDefaults] setObject:res forKey:key];
    }
    self.result = res;
    return;
}

- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key
{
    if (key.length == 0) {
        return;
    }
    if (!object) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        self.result = @([self removeValueForKey:key]);
        return;
    }
    dispatch_async(self.abQueue, ^{
        [self setObjectByInfo:@{@"obj":object,@"key":key}];
    });
}

- (void)setObjectByInfo:(NSDictionary *)info
{
    self.result = @(NO);
    id<NSCoding> object = [info objectForKey:@"obj"];
    NSString *key = [info objectForKey:@"key"];
    if (key.length == 0) {
        return;
    }
    
    if (self.useUserDefaultCache) {
        if (object) {
            [[NSUserDefaults standardUserDefaults] setObject:object forKey:key];
        } else {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    }
    
    if (!object) {
        self.result = @([self removeValueForKey:key]);
        return;
    }
    
    if (![NSJSONSerialization isValidJSONObject:object]) {
        NSLog(@"%@", @"keyChain object must be valid json object");
        return;
    }
    
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    } @catch (NSException *exception) {
        data = nil;
        NSLog(@"keyChain setObject failed: %@", exception);
    }
    
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithCapacity:4];
    [query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
    [query setObject:self.serviceName forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [query setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    [query setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    if (status == errSecSuccess) {
        if (data) {
            NSMutableDictionary *updateDict = [NSMutableDictionary dictionaryWithCapacity:2];
            [updateDict setObject:data forKey:(__bridge id<NSCopying>)(kSecValueData)];
            status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)updateDict);
            if (status == errSecSuccess) {
                self.result = @(YES);
            }
        } else {
            self.result = @([self removeValueForKey:key]);
        }
    } else if(status == errSecItemNotFound) {
        if (data) {
            NSMutableDictionary *attrs = [NSMutableDictionary dictionaryWithCapacity:5];
            [attrs setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
            [attrs setObject:self.serviceName forKey:(__bridge id<NSCopying>)(kSecAttrService)];
            [attrs setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
            [attrs setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
            [attrs setObject:data forKey:(__bridge id<NSCopying>)(kSecValueData)];
            status = SecItemAdd((__bridge CFDictionaryRef)attrs, NULL);
            self.result = @(status == errSecSuccess);
        }
    }
}

- (BOOL)removeValueForKey:(NSString *)key
{
    __block BOOL result = NO;
    bd_dispatch_sync_wait(self.abQueue, ^{
        [self doRemoveValueForKey:key];
        result = self.result;
    }, 1.0);
    return result;
}

- (void)doRemoveValueForKey:(NSString *)key
{
    self.result = @(NO);
    if(key.length == 0) return;
    
    if (self.useUserDefaultCache) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
    
    NSMutableDictionary *itemToDelete = [NSMutableDictionary dictionaryWithCapacity:6];
    [itemToDelete setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
    [itemToDelete setObject:self.serviceName forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [itemToDelete setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    [itemToDelete setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)itemToDelete);
    self.result = @(status == errSecSuccess || status == errSecItemNotFound);
}

- (BOOL)hasObjectForKey:(NSString *)key
{
    __block BOOL result = NO;
    bd_dispatch_sync_wait(self.abQueue, ^{
        [self doHasObjectForKey:key];
        result = self.result;
    }, 1.0);
    return result;
}

- (void)doHasObjectForKey:(NSString *)key
{
    self.result = @(NO);
    if(key.length == 0) return;
    
    if (self.useUserDefaultCache) {
        self.result = [[NSUserDefaults standardUserDefaults] objectForKey:key] ? @(YES) : @(NO);
    }
    
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithCapacity:4];
    [query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
    [query setObject:self.serviceName forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    [query setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrAccount)];
    [query setObject:key forKey:(__bridge id<NSCopying>)(kSecAttrGeneric)];
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
    self.result = @(status == errSecSuccess);
}

- (BOOL)removeAll
{
    __block BOOL result = NO;
    bd_dispatch_sync_wait(self.abQueue, ^{
        [self doRemoveAll];
        result = self.result;
    }, 1.0);
    return result;
}

- (void)doRemoveAll
{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithCapacity:6];
    [query setObject:(__bridge id)(kSecClassGenericPassword) forKey:(__bridge id<NSCopying>)(kSecClass)];
    [query setObject:self.serviceName forKey:(__bridge id<NSCopying>)(kSecAttrService)];
    //    [query setObject:(__bridge id)(kSecMatchLimitAll) forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef)query);
    self.result = @(status == errSecSuccess || status == errSecItemNotFound);
}

@end
