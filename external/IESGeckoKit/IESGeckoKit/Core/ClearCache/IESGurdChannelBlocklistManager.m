
#import "IESGurdChannelBlocklistManager.h"
#import "NSData+IESGurdKit.h"
#import "IESGurdKit+Experiment.h"
#import "IESGeckoKit+Private.h"
#import "IESGeckoDefines+Private.h"
#import "IESGurdAppLogger.h"
#import "IESGurdFilePaths.h"
#import "IESGurdAppLog.h"
#import "IESGurdLogProxy.h"
#import <objc/runtime.h>

@interface IESGurdChannelBlocklistManager ()

// 黑名单 channel, NSMutableDictionary for fast search and serialization
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *blocklistChannelDictionary;

@end

@implementation IESGurdChannelBlocklistManager

+ (instancetype)sharedManager
{
    static IESGurdChannelBlocklistManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.blocklistChannelDictionary = [self cachedBlocklist] ?: [NSMutableDictionary dictionary];
    });
    return manager;
}

- (void)addChannel:(NSString *)channel forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    @synchronized (self) {
        NSMutableDictionary<NSString *, NSNumber *> *channelsDictionary = self.blocklistChannelDictionary[accessKey];
        if (!channelsDictionary) {
            channelsDictionary = [NSMutableDictionary dictionary];
            self.blocklistChannelDictionary[accessKey] = channelsDictionary;
        }
        channelsDictionary[channel] = @(1);
        
        [self syncBlocklist];
    }
}

- (void)removeChannel:(NSString *)channel forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || channel.length == 0) {
        return;
    }
    @synchronized (self) {
        NSMutableDictionary<NSString *, NSNumber *> *channelsDictionary = self.blocklistChannelDictionary[accessKey];
        if (!channelsDictionary) {
            return;
        }
        [channelsDictionary removeObjectForKey:channel];
        // 如果 channel 空了删掉 accesskey，否则越来越大
        if (channelsDictionary.count == 0) {
            [self.blocklistChannelDictionary removeObjectForKey:accessKey];
        }
        
        [self syncBlocklist];
    }
}

- (BOOL)isBlocklistChannel:(NSString *)channel accessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || channel.length == 0) {
        return NO;
    }
    @synchronized (self) {
        return [self.blocklistChannelDictionary[accessKey][channel] boolValue];
    }
}

- (NSUInteger)getBlocklistCount:(NSString *)accessKey
{
    if (accessKey.length == 0) {
        return 0;
    }
    @synchronized (self) {
        return self.blocklistChannelDictionary[accessKey].count;
    }
}

- (NSDictionary<NSString *, NSArray<NSString *> *> *)copyBlocklistChannel
{
    @synchronized (self) {
        NSMutableDictionary<NSString *, NSArray<NSString *> *> *result = [NSMutableDictionary dictionary];
        [self.blocklistChannelDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull accesskey, NSMutableDictionary<NSString *, NSNumber *> * _Nonnull channels, BOOL * _Nonnull stop) {
            result[accesskey] = channels.allKeys;
        }];
        return [result copy];
    }
}

- (void)cleanCache
{
    self.blocklistChannelDictionary = [NSMutableDictionary dictionary];
    [self syncBlocklist];
}

#pragma mark - Private

// 持久化黑名单
- (void)syncBlocklist
{
    if (![IESGurdKit didSetup]) {
        return;
    }
    
    NSDictionary *lastSyncDictionary = objc_getAssociatedObject(self, _cmd);
    NSDictionary *currentDictionary = [[NSDictionary alloc] initWithDictionary:self.blocklistChannelDictionary copyItems:YES];
    if ([currentDictionary isEqualToDictionary:lastSyncDictionary]) {
        return;
    }
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:currentDictionary options:0 error:NULL];
    if (![data writeToFile:IESGurdFilePaths.blocklistChannelPath atomically:YES]) {
        return;
    }
    
    uint32_t crc32 = [data iesgurdkit_crc32];
    NSData *crc32Data = [NSData dataWithBytes:&crc32 length:sizeof(crc32)];
    if ([crc32Data writeToFile:IESGurdFilePaths.blocklistChannelCrc32Path atomically:YES]) {
        objc_setAssociatedObject(self, _cmd, currentDictionary, OBJC_ASSOCIATION_COPY_NONATOMIC);
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:IESGurdFilePaths.blocklistChannelPath error:NULL];
    }
}

// 获取缓存黑名单
+ (NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *)cachedBlocklist
{
    if (![IESGurdKit didSetup]) {
        return nil;
    }
    
    // 二进制数据
    NSData *blocklistChannelData = [self dataWithPath:IESGurdFilePaths.blocklistChannelPath];
    if (blocklistChannelData.length == 0) {
        return nil;
    }
    
    // crc32 校验码
    NSData *crc32Data = [self dataWithPath:IESGurdFilePaths.blocklistChannelCrc32Path];
    if (crc32Data.length == 0) {
        return nil;
    }
    
    uint32_t crc32;
    [crc32Data getBytes:&crc32 length:sizeof(crc32)];
    // 校验二进制数据
    if ([blocklistChannelData iesgurdkit_crc32] != crc32) {
        BOOL uploadAlog = NO;
        NSString *deviceID = IESGurdKitInstance.deviceID;
        if ([deviceID hasPrefix:@"4"]) {
            uploadAlog = YES;
            IESGurdLogError(@"cachedBlocklist failed: blocklistChannelData is %@, crc32Data is %@", [[NSString alloc] initWithData:blocklistChannelData encoding:NSUTF8StringEncoding], [[NSString alloc] initWithData:crc32Data encoding:NSUTF8StringEncoding]);
        }
        [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeClearCache
                                      subtype:IESGurdAppLogEventSubtypeBlocklistValidateFailed
                                       params:nil
                                    extraInfo:[NSString stringWithFormat:@"%d", uploadAlog]
                                 errorMessage:nil];
        [[NSFileManager defaultManager] removeItemAtPath:IESGurdFilePaths.blocklistChannelPath error:NULL];
        [[NSFileManager defaultManager] removeItemAtPath:IESGurdFilePaths.blocklistChannelCrc32Path error:NULL];
        return nil;
    }
    
    NSDictionary *blocklistChannel = [NSJSONSerialization JSONObjectWithData:blocklistChannelData
                                                                     options:0
                                                                       error:NULL];
    
    if (!GURD_CHECK_DICTIONARY(blocklistChannel)) {
        return nil;
    }
    
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, NSNumber *> *> *result = [NSMutableDictionary dictionary];
    [blocklistChannel enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSDictionary *channels, BOOL *stop) {
        NSMutableDictionary<NSString *, NSNumber *> *channelsDictionary = [NSMutableDictionary dictionary];
        [channels enumerateKeysAndObjectsUsingBlock:^(NSString *channel, id obj, BOOL *stop) {
            channelsDictionary[channel] = @(1);
        }];
        result[accessKey] = channelsDictionary;
    }];
    return result;
}

+ (NSData *)dataWithPath:(NSString *)path
{
    return [NSData dataWithContentsOfFile:path
                                  options:NSDataReadingMappedIfSafe
                                    error:NULL];
}

@end
