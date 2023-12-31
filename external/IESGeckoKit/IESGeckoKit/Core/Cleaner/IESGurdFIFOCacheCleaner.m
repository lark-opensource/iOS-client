//
//  IESGurdFIFOCacheCleaner.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/6.
//

#import "IESGurdFIFOCacheCleaner.h"

#import "IESGurdActivePackageMeta.h"

@interface IESGurdFIFOCacheCleaner ()

@property (nonatomic, strong) IESGurdCacheConfiguration *configuration;

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, strong) NSMutableArray<NSString *> *channelsArray;

@property (nonatomic, assign) NSInteger capacity;

@property (nonatomic, strong) NSLock *channelsArrayLock;

@end

@implementation IESGurdFIFOCacheCleaner

#pragma mark - IESGurdCacheCleaner

+ (instancetype)cleanerWithAccessKey:(NSString *)accessKey
                   channelMetasArray:(NSArray<IESGurdActivePackageMeta *> *)channelMetasArray
                       configuration:(IESGurdCacheConfiguration *)configuration
{
    IESGurdFIFOCacheCleaner *cleaner = [[self alloc] init];
    cleaner.accessKey = accessKey;
    NSMutableArray *channels = [NSMutableArray array];
    channelMetasArray = [channelMetasArray sortedArrayUsingComparator:^NSComparisonResult(IESGurdActivePackageMeta *obj1, IESGurdActivePackageMeta *obj2) {
        return obj1.lastUpdateTimestamp > obj2.lastUpdateTimestamp;
    }];
    [channelMetasArray enumerateObjectsUsingBlock:^(IESGurdActivePackageMeta *obj, NSUInteger idx, BOOL *stop) {
        NSString *channel = obj.channel;
        if (channel.length > 0) {
            [channels addObject:channel];
        }
    }];
    cleaner.channelsArray = channels;
    cleaner.configuration = configuration;
    cleaner.capacity = configuration.channelLimitCount;
    cleaner.channelsArrayLock = [[NSLock alloc] init];
    return cleaner;
}

- (NSArray<NSString *> *)activeChannels
{
    [self.channelsArrayLock lock];
    NSArray<NSString *> *channels = [self.channelsArray copy];
    [self.channelsArrayLock unlock];
    return channels;
}

- (NSArray<NSString *> *)channelsToBeCleaned
{
    [self.channelsArrayLock lock];
    
    NSArray<NSString *> *channels = nil;
    NSInteger channelsToBeCleanedCount = self.channelsArray.count - self.capacity;
    if (channelsToBeCleanedCount > 0) {
        channels = [self.channelsArray subarrayWithRange:NSMakeRange(0, channelsToBeCleanedCount)];
    }
    [self.channelsArrayLock unlock];
    
    return channels;
}

- (void)gurdDidApplyPackageForChannel:(NSString *)channel
{
    [self.channelsArrayLock lock];
    
    if (![self.channelsArray containsObject:channel]) {
        [self.channelsArray addObject:channel];
    }
    
    [self.channelsArrayLock unlock];
}

- (void)gurdDidCleanPackageForChannel:(NSString *)channel
{
    [self.channelsArrayLock lock];
    
    if ([self.channelsArray containsObject:channel]) {
        [self.channelsArray removeObject:channel];
    }
    
    [self.channelsArrayLock unlock];
}

- (void)gurdDidAddChannelWhitelist:(NSArray<NSString *> *)channelWhitelist
{
    [self.channelsArrayLock lock];
    
    [channelWhitelist enumerateObjectsUsingBlock:^(NSString *channel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.channelsArray containsObject:channel]) {
            [self.channelsArray removeObject:channel];
        }
    }];
    
    [self.channelsArrayLock unlock];
}

- (NSString *)cleanerTypeString
{
    return @"FIFO";
}

- (NSDictionary<NSString *,NSString *> *)debugInfoDictionary
{
    return @{ @"Channels limit count" : @(self.capacity).stringValue,
              @"Active channels" : [[self.channelsArray copy] componentsJoinedByString:@"、"] ? : @"None" };
}

@end
