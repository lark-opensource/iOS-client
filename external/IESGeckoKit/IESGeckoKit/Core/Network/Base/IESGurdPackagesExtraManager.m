//
//  IESGurdPackagesExtraManager.m
//  IESGeckoKit
//
//  Created by xinwen tan on 2022/2/17.
//

#import "IESGurdPackagesExtraManager.h"
#import "IESGurdFilePaths.h"
#import "IESGurdAppLogger.h"

@interface IESGurdPackagesExtraManager ()

@property (nonatomic, strong) NSMutableDictionary *extras;
@property (nonatomic, strong) NSLock *innerLock;
@property (nonatomic, assign) BOOL dirty;

- (void)readCache;

@end

@implementation IESGurdPackagesExtraManager

+ (instancetype)sharedManager
{
    static IESGurdPackagesExtraManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        manager.innerLock = [[NSLock alloc] init];
    });
    return manager;
}

- (void)setup
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.innerLock lock];
        if (!self.extras) {
            [self readCache];
        }
        [self.innerLock unlock];
    });
}

- (void)readCache
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:IESGurdFilePaths.packagesExtraPath]) {
        self.extras = [NSMutableDictionary dictionaryWithContentsOfFile:IESGurdFilePaths.packagesExtraPath];
        if (!self.extras) {
            self.extras = [NSMutableDictionary dictionary];
            [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeExtra
                                          subtype:IESGurdAppLogEventSubtypeReadExtraError
                                           params:nil
                                        extraInfo:nil
                                     errorMessage:@""];
        }
    } else {
        self.extras = [NSMutableDictionary dictionary];
    }
}

- (nullable NSDictionary *)getExtra:(NSString *)accsskey channel:(NSString *)channel
{
    [self.innerLock lock];
    NSDictionary *extra = nil;
    if (self.extras) {
        NSString *key = [NSString stringWithFormat:@"%@_%@", accsskey, channel];
        extra = self.extras[key];
    }
    [self.innerLock unlock];
    return extra;
}

- (void)updateExtra:(NSString *)accsskey channel:(NSString *)channel data:(NSDictionary *)data
{
    [self.innerLock lock];
    if (!self.extras) {
        [self readCache];
    }
    NSString *key = [NSString stringWithFormat:@"%@_%@", accsskey, channel];
    self.extras[key] = data;
    self.dirty = YES;
    [self.innerLock unlock];
}

- (void)cleanExtraIfNeeded:(NSString *)accsskey channel:(NSString *)channel
{
    [self.innerLock lock];
    if (!self.extras) {
        [self readCache];
    }
    NSString *key = [NSString stringWithFormat:@"%@_%@", accsskey, channel];
    if (self.extras[key]) {
        self.extras[key] = nil;
        self.dirty = YES;
    }
    [self.innerLock unlock];
}

- (void)saveToFile
{
    [self.innerLock lock];
    if (self.extras && self.dirty) {
        if (![self.extras writeToFile:IESGurdFilePaths.packagesExtraPath atomically:YES]) {
            [IESGurdAppLogger recordEventWithType:IESGurdAppLogEventTypeExtra
                                          subtype:IESGurdAppLogEventSubtypeWriteExtraError
                                           params:nil
                                        extraInfo:nil
                                     errorMessage:@""];
        }
        self.dirty = NO;
    }
    [self.innerLock unlock];
}

@end
