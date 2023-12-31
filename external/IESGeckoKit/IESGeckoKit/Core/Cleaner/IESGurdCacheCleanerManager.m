//
//  IESGurdCacheCleanerManager.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/6.
//

#import "IESGurdCacheCleanerManager.h"

//meta
#import "IESGurdResourceMetadataStorage.h"
//cleaner
#import "IESGurdFIFOCacheCleaner.h"
#import "IESGurdLRUCacheCleaner.h"

@interface IESGurdCacheCleanerManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, id<IESGurdCacheCleaner>> *cleanerDictionary;

@property (nonatomic, strong) NSLock *cleanerLock;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *channelsWhitelist;

@end

@implementation IESGurdCacheCleanerManager

+ (instancetype)sharedManager
{
    static IESGurdCacheCleanerManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.cleanerLock = [[NSLock alloc] init];
        [manager setupNotification];
    });
    return manager;
}

#pragma mark - Public

- (void)registerCacheCleanerForAccessKey:(NSString *)accessKey
                           configuration:(IESGurdCacheConfiguration *)configuration
{
    [self.cleanerLock lock];
    
    Class cleanerClass = [self cleanerClassWithPolicy:configuration.cachePolicy];
    if (cleanerClass) {
        NSArray<IESGurdActivePackageMeta *> *channelMetasArray = [IESGurdResourceMetadataStorage copyActiveMetadataDictionary][accessKey].allValues;
        id<IESGurdCacheCleaner> cleaner = [cleanerClass cleanerWithAccessKey:accessKey
                                                           channelMetasArray:channelMetasArray
                                                               configuration:configuration];
        if (cleaner) {
            self.cleanerDictionary[accessKey] = cleaner;
        }
    }
    
    [self.cleanerLock unlock];
}

- (id<IESGurdCacheCleaner>)cleanerForAccessKey:(NSString *)accessKey
{
    id<IESGurdCacheCleaner> cleaner = nil;
    [self.cleanerLock lock];
    cleaner = self.cleanerDictionary[accessKey];
    [self.cleanerLock unlock];
    return cleaner;
}

- (void)addChannelsWhitelist:(NSArray<NSString *> *)channels
                forAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || channels.count == 0) {
        return;
    }
    @synchronized (self) {
        NSMutableArray *array = self.channelsWhitelist[accessKey];
        if (!array) {
            array = [NSMutableArray arrayWithArray:channels];
            self.channelsWhitelist[accessKey] = array;
        } else {
            [channels enumerateObjectsUsingBlock:^(NSString *channel, NSUInteger idx, BOOL *stop) {
                if (![array containsObject:channel]) {
                    [array addObject:channel];
                }
            }];
        }
    }
    [[self cleanerForAccessKey:accessKey] gurdDidAddChannelWhitelist:channels];
}

- (BOOL)isChannelInWhitelist:(NSString *)channel
                   accessKey:(NSString *)accessKey
{
    if (accessKey.length == 0 || channel.length == 0) {
        return NO;
    }
    __block BOOL isInWhitelist = NO;
    @synchronized (self) {
        NSMutableArray *array = self.channelsWhitelist[accessKey];
        isInWhitelist = [array containsObject:channel];
    }
    return isInWhitelist;
}

- (NSArray<NSString *> *)channelWhitelistForAccessKey:(NSString *)accessKey
{
    if (accessKey.length == 0) {
        return @[];
    }
    __block NSArray *channelWhitelist = nil;
    @synchronized (self) {
        channelWhitelist = [self.channelsWhitelist[accessKey] copy];
    }
    return channelWhitelist;
}

- (NSDictionary<NSString *, id<IESGurdCacheCleaner>> *)cleaners
{
    NSDictionary *cleaners = nil;
    [self.cleanerLock lock];
    cleaners = [self.cleanerDictionary copy];
    [self.cleanerLock unlock];
    return cleaners;
}

#pragma mark - Private

- (void)setupNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(cleanCacheIfNeeded)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
}

- (void)cleanCacheIfNeeded
{
    if (![self.delegate respondsToSelector:@selector(cacheCleanerManager:cleanCacheForAccessKey:channelsToBeCleaned:cachePolicy:enableAppLog:)]) {
        return;
    }
    
    NSDictionary *cleaners = nil;
    [self.cleanerLock lock];
    cleaners = [self.cleanerDictionary copy];
    [self.cleanerLock unlock];
    
    [cleaners enumerateKeysAndObjectsUsingBlock:^(NSString *accessKey, id<IESGurdCacheCleaner> cleaner, BOOL *stop) {
        NSArray<NSString *> *channelsToBeCleaned = [cleaner channelsToBeCleaned];
        if (channelsToBeCleaned.count > 0) {
            [self.delegate cacheCleanerManager:self
                        cleanCacheForAccessKey:accessKey
                           channelsToBeCleaned:channelsToBeCleaned
                                   cachePolicy:cleaner.configuration.cachePolicy
                                  enableAppLog:cleaner.configuration.enableAppLog];
        }
    }];
}

- (Class)cleanerClassWithPolicy:(IESGurdCleanCachePolicy)cleanPolicy
{
    static NSDictionary *cleanerClassDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cleanerClassDictionary = @{ @(IESGurdCleanCachePolicyFIFO) : [IESGurdFIFOCacheCleaner class],
                                    @(IESGurdCleanCachePolicyLRU) : [IESGurdLRUCacheCleaner class] };
    });
    
    return cleanerClassDictionary[@(cleanPolicy)];
}

#pragma mark - Getter

- (NSMutableDictionary<NSString *, id<IESGurdCacheCleaner>> *)cleanerDictionary
{
    if (!_cleanerDictionary) {
        _cleanerDictionary = [NSMutableDictionary dictionary];
    }
    return _cleanerDictionary;
}

- (NSMutableDictionary<NSString *, NSMutableArray<NSString *> *> *)channelsWhitelist {
    if (!_channelsWhitelist) {
        _channelsWhitelist = [NSMutableDictionary dictionary];
    }
    return _channelsWhitelist;
}

@end
