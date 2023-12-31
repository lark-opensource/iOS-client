//
//  IESGurdLRUCacheCleaner.m
//  Pods
//
//  Created by 陈煜钏 on 2019/8/19.
//

#import "IESGurdLRUCacheCleaner.h"

#import "IESGurdLRUCacheLinkedList.h"
#import "IESGurdActivePackageMeta.h"

@interface IESGurdLRUCacheCleaner ()

@property (nonatomic, strong) IESGurdCacheConfiguration *configuration;

@property (nonatomic, copy) NSString *accessKey;

@property (nonatomic, strong) IESGurdLRUCacheLinkedList *channelsLinkedList;

@end

@implementation IESGurdLRUCacheCleaner

#pragma mark - IESGurdCacheCleaner

+ (instancetype)cleanerWithAccessKey:(NSString *)accessKey
                   channelMetasArray:(NSArray<IESGurdActivePackageMeta *> *)channelMetasArray
                       configuration:(IESGurdCacheConfiguration *)configuration
{
    IESGurdLRUCacheCleaner *cleaner = [[self alloc] init];
    cleaner.accessKey = accessKey;
    cleaner.configuration = configuration;
    
    IESGurdLRUCacheLinkedList *linkedList = [[IESGurdLRUCacheLinkedList alloc] init];
    channelMetasArray = [channelMetasArray sortedArrayUsingComparator:^NSComparisonResult(IESGurdActivePackageMeta *obj1, IESGurdActivePackageMeta *obj2) {
        return obj1.lastReadTimestamp < obj2.lastReadTimestamp;
    }];
    [channelMetasArray enumerateObjectsUsingBlock:^(IESGurdActivePackageMeta *obj, NSUInteger idx, BOOL *stop) {
        NSString *channel = obj.channel;
        if (channel.length > 0) {
            [linkedList appendLinkedNodeForChannel:channel];
        }
    }];
    linkedList.capacity = configuration.channelLimitCount;
    cleaner.channelsLinkedList = linkedList;
    
    return cleaner;
}

- (NSArray<NSString *> *)activeChannels
{
    return [self.channelsLinkedList allChannels];
}

- (NSArray<NSString *> *)channelsToBeCleaned
{
    return [self.channelsLinkedList channelsToBeDelete];
}

- (void)gurdDidApplyPackageForChannel:(NSString *)channel
{
    [self.channelsLinkedList appendLinkedNodeForChannel:channel];
}

- (void)gurdDidGetCachePackageForChannel:(NSString *)channel
{
    [self.channelsLinkedList bringLinkedNodeToHeadForChannel:channel];
}

- (void)gurdDidCleanPackageForChannel:(NSString *)channel
{
    [self.channelsLinkedList deleteLinkedNodeForChannel:channel];
}

- (void)gurdDidAddChannelWhitelist:(NSArray<NSString *> *)channelWhitelist
{
    [channelWhitelist enumerateObjectsUsingBlock:^(NSString *channel, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.channelsLinkedList deleteLinkedNodeForChannel:channel];
    }];
}

- (NSString *)cleanerTypeString
{
    return @"LRU";
}

- (NSDictionary<NSString *,NSString *> *)debugInfoDictionary
{
    return @{ @"Channels limit count" : @(self.channelsLinkedList.capacity).stringValue,
              @"Active channels" : [self.channelsLinkedList description] ? : @"None" };
}

@end
