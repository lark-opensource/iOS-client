//
//  IESGurdResourceMetadataCache.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2021/2/3.
//

#import "IESGurdResourceMetadataCache.h"

#import "IESGeckoDefines+Private.h"
#import "IESGurdAppLogger.h"
#import "IESGurdLogProxy.h"
#import "IESGurdEventTraceManager+Business.h"
#import <IESMetadataStorage/IESMetadataStorage.h>
#import <IESMetadataStorage/IESMetadataLog.h>
#import <objc/runtime.h>

@implementation IESMetadataStorageConfiguration (IESGurdKit)
- (BOOL)enableIndexLog
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}
- (void)setEnableIndexLog:(BOOL)enableIndexLog
{
    objc_setAssociatedObject(self, @selector(enableIndexLog), @(enableIndexLog), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end

@interface IESGurdResourceMetadataCache ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id<IESGurdMetadataProtocol>> *> *metadataDictionary;

@property (nonatomic, strong) IESMetadataStorage *metadataStorage;

@end

@implementation IESGurdResourceMetadataCache

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        IESMetadataLogBlock logBlock = ^(IESMetadataLogLevel level, NSString *message) {
            switch (level) {
                case IESMetadataLogLevelInfo: {
                    IESGurdLogInfo(@"%@", message);
                    break;
                }
                case IESMetadataLogLevelWarning: {
                    IESGurdLogWarning(@"%@", message);
                    break;
                }
                case IESMetadataLogLevelError: {
                    IESGurdLogError(@"%@", message);
                    break;
                }
            }
            
            if (level == IESMetadataLogLevelError) {
                [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeMetadata
                                              subtype:IESGurdAppLogEventSubtypeMetadataInternalError
                                               params:nil
                                            extraInfo:nil
                                         errorMessage:message];
            }
        };
        IESMetadataSetLogBlock(logBlock);
    });
}

+ (instancetype)metadataCacheWithConfiguration:(IESMetadataStorageConfiguration *)configuration
                                 metadataClass:(Class<IESGurdMetadataProtocol>)metadataClass
{
    IESGurdResourceMetadataCache *cache = [[self alloc] init];
    [cache loadMetadataWithConfiguration:configuration metadataClass:metadataClass];
    return cache;
}

- (void)saveMetadata:(id<IESGurdMetadataProtocol>)metadata
{
    NSString *accessKey = metadata.accessKey;
    NSString *channel = metadata.channel;
    if (!metadata || accessKey.length == 0 || channel.length == 0) {
        NSAssert(NO, @"Save metadata failed, %@ %@", accessKey ? : @"", channel ? : @"");
        return;
    }
    
    [self cacheMetadataInMemory:metadata isDuplicated:NULL];
    
    NSError *error = nil;
    int writeIndex = [self.metadataStorage writeMetadata:metadata error:&error];
    if (writeIndex < 0) {
        NSString *message = [NSString stringWithFormat:@"write metadata error : %@", error.localizedDescription];
        IESGurdTraceMessageInfo *messageInfo = [IESGurdTraceMessageInfo messageInfoWithAccessKey:accessKey
                                                                                         channel:channel
                                                                                         message:message
                                                                                        hasError:YES];
        messageInfo.shouldLog = YES;
        [IESGurdEventTraceManager traceEventWithMessageInfo:messageInfo];
        
        NSString *extraInfo = [NSString stringWithFormat:@"%@|%@", accessKey, channel];
        [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeMetadata
                                      subtype:IESGurdAppLogEventSubtypeMetadataWriteFailed
                                       params:nil
                                    extraInfo:extraInfo
                                 errorMessage:error.localizedDescription];
    }
    if (self.metadataStorage.configuration.enableIndexLog) {
        IESGurdLogInfo(@"write metadata(%@) at index(%d)", [metadata metadataIdentity], writeIndex);
    }
}

- (void)deleteMetadataForAccessKey:(NSString *)accessKey
                           channel:(NSString *)channel
{
    id<IESMetadataProtocol> metadata = self.metadataDictionary[accessKey][channel];
    self.metadataDictionary[accessKey][channel] = nil;
    
    if (metadata) {
        [self.metadataStorage deleteMetadata:metadata];
    }
}

- (void)clearAllMetadata
{
    self.metadataDictionary = [NSMutableDictionary dictionary];
    
    [self.metadataStorage deleteAllMetadata];
}

- (NSDictionary<NSString *, NSDictionary<NSString *, id> *> *)copyMetadataDictionary
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self.metadataDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, NSMutableDictionary<NSString *, id> *obj, BOOL *stop) {
        if (obj.count > 0) {
            dictionary[accessKey] = [obj copy];
        }
    }];
    return [dictionary copy];
}

- (NSMutableDictionary *)objectForKeyedSubscript:(NSString *)key
{
    return self.metadataDictionary[key];
}

- (void)setObject:(NSMutableDictionary *)obj forKeyedSubscript:(NSString *)key
{
    NSAssert(NO, @"Metadata dictionary is not allowed to modify");
}

#pragma mark - Private

- (void)loadMetadataWithConfiguration:(IESMetadataStorageConfiguration *)configuration
                        metadataClass:(Class<IESGurdMetadataProtocol>)metadataClass
{
    IESMetadataStorage *storage = [IESMetadataStorage storageWithConfiguration:configuration];
    self.metadataStorage = storage;
    self.metadataDictionary = [NSMutableDictionary dictionary];
    
    NSArray<id<IESGurdMetadataProtocol>> *metadatasArray = [storage metadatasArrayWithTransformBlock:^IESMetadataType * _Nonnull(NSData * _Nonnull data) {
        return [metadataClass metaWithData:data];
    } compareBlock:^BOOL(IESMetadataType *first, IESMetadataType *another) {
        return ((NSObject<IESGurdMetadataProtocol> *)another).packageID > ((NSObject<IESGurdMetadataProtocol> *)first).packageID;
    }];
    
    BOOL enableIndexLog = configuration.enableIndexLog;
    __block NSInteger duplicatedMetadataCount = 0;
    NSMutableArray<NSString *> *indexStrings = enableIndexLog ? [NSMutableArray array] : nil;
    [metadatasArray enumerateObjectsUsingBlock:^(id<IESGurdMetadataProtocol> metadata, NSUInteger idx, BOOL *stop) {
        BOOL isDuplicated = NO;
        [self cacheMetadataInMemory:metadata isDuplicated:&isDuplicated];
        if (isDuplicated) {
            duplicatedMetadataCount++;
        }
        if (enableIndexLog) {
            NSString *indexString = [NSString stringWithFormat:@"%@-%llu-%d",
                                     metadata.channel,
                                     metadata.packageID,
                                     [storage indexForMetadata:metadata]] ? : @"";
            [indexStrings addObject:indexString];
            
            if (indexStrings.count >= 10) {
                IESGurdLogInfo(@"metadata indexes : %@", [indexStrings componentsJoinedByString:@"、"]);
                [indexStrings removeAllObjects];
            }
        }
    }];
    if (duplicatedMetadataCount > 0) {
        // 下次冷启去重
        [storage setNeedCheckDuplicatedMetadatas];
        
        [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeMetadata
                                      subtype:IESGurdAppLogEventSubtypeMetadataDuplicated
                                       params:@{ @"count" : @(duplicatedMetadataCount) }
                                    extraInfo:nil
                                 errorMessage:nil];
    }
    if (enableIndexLog && indexStrings.count > 0) {
        IESGurdLogInfo(@"metadata indexes : %@", [indexStrings componentsJoinedByString:@"、"]);
    }
}

- (void)cacheMetadataInMemory:(id<IESGurdMetadataProtocol>)metadata isDuplicated:(BOOL *)isDuplicated
{
    NSString *accessKey = metadata.accessKey;
    NSString *channel = metadata.channel;
    if (!metadata || accessKey.length == 0 || channel.length == 0) {
        return;
    }
    NSMutableDictionary *channelDictionary = self.metadataDictionary[accessKey];
    if (!channelDictionary) {
        channelDictionary = [NSMutableDictionary dictionary];
        self.metadataDictionary[accessKey] = channelDictionary;
    }
    if (channelDictionary[channel] && isDuplicated) {
        *isDuplicated = YES;
    }
    channelDictionary[channel] = metadata;
}

#pragma mark - Accessor

- (int)version
{
    return self.metadataStorage.version;
}

@end
