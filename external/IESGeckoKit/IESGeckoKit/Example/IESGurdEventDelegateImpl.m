//
//  IESGurdEventDelegateImpl.m
//  IESGeckoKit
//
//  Created by 陈煜钏 on 2020/8/14.
//

#import "IESGurdEventDelegateImpl.h"

#import <IESGeckoKit/IESGeckoKit.h>

static NSString *IESGurdLogLevelString (IESGurdLogLevel level)
{
    return @{ @(IESGurdLogLevelInfo) : @"Info",
              @(IESGurdLogLevelWarning) : @"Warning",
              @(IESGurdLogLevelError) : @"Error" }[@(level)];
}

@interface IESGurdEventDelegateImpl () <IESGurdEventDelegate, IESGurdLogProxyDelegate>

@end

@implementation IESGurdEventDelegateImpl

+ (void)load
{
    [IESGurdKit registerEventDelegate:[self sharedInstance]];
    [IESGurdKit addGurdLogDelegate:[self sharedInstance]];
}

+ (IESGurdEventDelegateImpl *)sharedInstance
{
    static IESGurdEventDelegateImpl *impl = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        impl = [[self alloc] init];
    });
    return impl;
}

#pragma mark - IESGurdLogProxyDelegate

- (void)gurdLogLevel:(IESGurdLogLevel)logLevel logMessage:(NSString *)logMessage
{
    logMessage = [NSString stringWithFormat:@"%@|%@", IESGurdLogLevelString(logLevel), logMessage];
    NSLog(@"【Log】%@", logMessage);
}

#pragma mark - IESGurdEventDelegate

- (void)gurdDidRequestConfigForAccessKey:(NSString *)accessKey
                       configsDictionary:(NSDictionary<NSString *, NSNumber *> *)configsDictionary
{
    NSLog(@"【EventDelegate】【Gurd Did Request Config】%@ | %@", accessKey, configsDictionary);
}

- (void)gurdDidEnqueueDownloadTaskForModel:(IESGurdResourceModel *)model
{
    NSLog(@"【EventDelegate】【Gurd Did Enqueue Download Task】%@ | %@ | %zd",
          model.accessKey, model.channel, model.downloadPriority);
}

- (void)gurdWillDownloadPackageForAccessKey:(NSString *)accessKey
                                    channel:(NSString *)channel
                                    isPatch:(BOOL)isPatch
{
    NSLog(@"【EventDelegate】【Gurd Will Download Package】%@ | %@ | %@", accessKey, channel, isPatch ? @"Patch" : @"Full");
}

- (void)gurdDidFinishDownloadingPackageForAccessKey:(NSString *)accessKey
                                            channel:(NSString *)channel
                                        packageInfo:(IESGurdDownloadPackageInfo *)packageInfo
{
    NSLog(@"【EventDelegate】【Gurd Did Finish Downloading Package】%@ | %@ | %@",
          accessKey, channel, packageInfo.isSuccessful ? @"succeed" : @"fail");
}

- (void)gurdDidFinishUnzippingPackageForAccessKey:(NSString *)accessKey
                                          channel:(NSString *)channel
                                      packageInfo:(IESGurdUnzipPackageInfo *)packageInfo
{
    NSLog(@"【EventDelegate】【Gurd Did Finish Unzipping Package】%@ | %@ | %@",
          accessKey, channel, packageInfo.isSuccessful ? @"succeed" : @"fail");
}

- (void)gurdDidFinishApplyingPackageForAccessKey:(NSString *)accessKey
                                         channel:(NSString *)channel
                                         succeed:(BOOL)succeed
                                           error:(NSError * _Nullable)error
{
    NSLog(@"【EventDelegate】【Gurd Did Finish Applying Package】%@ | %@ | %@",
          accessKey, channel, succeed ? @"succeed" : @"fail");
}

- (void)gurdDidCleanCachePackageForAccessKey:(NSString *)accessKey
                                     channel:(NSString *)channel
{
    NSLog(@"【EventDelegate】【Gurd Did Clean Cache】%@ | %@", accessKey, channel);
}

@end
