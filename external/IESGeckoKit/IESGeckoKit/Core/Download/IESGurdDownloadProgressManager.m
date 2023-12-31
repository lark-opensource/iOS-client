//
//  IESGurdDownloadProgressManager.m
//  IESGeckoKit
//
//  Created by bytedance on 2021/11/3.
//

#import "IESGurdDownloadProgressManager.h"

#import "IESGurdDownloadProgressObject+Private.h"

@interface IESGurdDownloadProgressManager ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, IESGurdDownloadProgressObject *> *progressObjectsDictionary;

@end

@implementation IESGurdDownloadProgressManager

+ (instancetype)sharedManager
{
    static IESGurdDownloadProgressManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.progressObjectsDictionary = [NSMutableDictionary dictionary];
    });
    return manager;
}

#pragma mark - Public

- (void)observeAccessKey:(NSString *)accessKey
                 channel:(NSString *)channel
   downloadProgressBlock:(void(^)(NSProgress *progress))downloadProgressBlock
{
    if (accessKey.length == 0 || channel.length == 0 || !downloadProgressBlock) {
        return;
    }
    NSString *identity = [NSString stringWithFormat:@"%@_%@", accessKey, channel];
    @synchronized (self) {
        IESGurdDownloadProgressObject *progressObject = self.progressObjectsDictionary[identity];
        if (!progressObject) {
            progressObject = [IESGurdDownloadProgressObject object];
            self.progressObjectsDictionary[identity] = progressObject;
        }
        [progressObject addProgressBlock:downloadProgressBlock];
    }
}

- (IESGurdDownloadProgressObject *)progressObjectForIdentity:(NSString *)identity
{
    @synchronized (self) {
        __block IESGurdDownloadProgressObject *downloadProgressObject = nil;
        [self.progressObjectsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, IESGurdDownloadProgressObject *obj, BOOL *stop) {
            NSString *prefix = [NSString stringWithFormat:@"%@_", key];
            if ([identity hasPrefix:prefix]) {
                downloadProgressObject = obj;
                *stop = YES;
            }
        }];
        return downloadProgressObject;
    }
}

- (void)removeObserverWithIdentity:(NSString *)identity
{
    @synchronized (self) {
        __block NSString *removeKey = nil;
        [self.progressObjectsDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, IESGurdDownloadProgressObject *obj, BOOL *stop) {
            NSString *prefix = [NSString stringWithFormat:@"%@_", key];
            if ([identity hasPrefix:prefix]) {
                removeKey = key;
                *stop = YES;
            }
        }];
        [self.progressObjectsDictionary removeObjectForKey:removeKey];
    }
}

@end
