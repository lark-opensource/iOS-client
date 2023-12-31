//
//  BDPreloadConfig.m
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/11.
//

#import "BDPreloadConfig.h"

@implementation BDPreloadConfig

+ (instancetype)sharedConfig {
    static BDPreloadConfig *_sharedSingleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedSingleton = [[self alloc] init];
    });
    return _sharedSingleton;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        NSString *tmpDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
        _diskCachePath = [tmpDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",@"bytewebview.preload"]];
        _diskCountLimit = 1000;
        _diskAgeLimit = 2 * 60 * 60;
        _memoryAgeLimit = 10 * 60;
        _memorySizeLimit = 100 * 1024 * 1024;
        _maxConcurrentTaskCount = 5;
        _maxConcurrentHardTaskCount = 3;
        _maxWaitTime = 5 * 60;
        _maxRunningTime = 5 * 60;
        _enableFollowRedirect = NO;
    }
    return self;
}

- (BOOL)needVerifySSL:(NSString *)urlString {
    if (urlString.length == 0) {
        return NO;
    }
    NSArray *sslURLList = self.skipSSLCertificateList;
    for (NSString *sslURL in sslURLList) {
        if ([sslURL containsString:urlString]) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)maxConcurrentTaskCountInWiFi {
    if (_maxConcurrentTaskCountInWiFi == 0) {
        return _maxConcurrentTaskCount;
    }
    return _maxConcurrentTaskCountInWiFi;
}

- (NSInteger)maxConcurrentHardTaskCountInWiFi {
    if (_maxConcurrentHardTaskCountInWiFi == 0) {
        return _maxConcurrentHardTaskCount;
    }
    return _maxConcurrentHardTaskCountInWiFi;
}

@end
