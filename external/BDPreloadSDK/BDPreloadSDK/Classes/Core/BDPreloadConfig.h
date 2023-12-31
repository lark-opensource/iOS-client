//
//  BDPreloadConfig.h
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPreloadConfig : NSObject

+ (instancetype)sharedConfig;

@property (nonatomic, strong) NSArray *skipSSLCertificateList;

/**
 * Default: /tmp/bytewebview.preload/
 */
@property (nonatomic, strong) NSString *diskCachePath;

/**
 * Default: 1000
 */
@property (nonatomic, assign) NSInteger diskCountLimit;
/**
 * Default: 2 hours
 */
@property (nonatomic, assign) NSTimeInterval diskAgeLimit;

/**
 * Default: 100 * 1024 * 1024
 */
@property (nonatomic, assign) NSInteger memorySizeLimit;
/**
 * Default: 600s
 */
@property (nonatomic, assign) NSTimeInterval memoryAgeLimit;

/**
 * 最大并发任务 Default: 5
 */
@property (nonatomic, assign) NSInteger maxConcurrentTaskCount;

/**
 * WiFi 下最大并发任务，不传默认 maxConcurrentTaskCount
 */
@property (nonatomic, assign) NSInteger maxConcurrentTaskCountInWiFi;

/**
 * 最大并发重任务 Default: 3
 */
@property (nonatomic, assign) NSInteger maxConcurrentHardTaskCount;

/**
 * WiFi 下最大并发任务，不传默认 maxConcurrentHardTaskCount
 */
@property (nonatomic, assign) NSInteger maxConcurrentHardTaskCountInWiFi;

/**
 * 队列中任务最长等待时间 Default: 5 * 60s
 */
@property (nonatomic, assign) NSTimeInterval maxWaitTime;

/**
 * 任务运行最长超时时间 Default: 5 * 60s
 */
@property (nonatomic, assign) NSTimeInterval maxRunningTime;

/**
 * 是否允许 WebView 重定向资源预加载，警告，某些场景下面开启可能导致 WebView 以为发生了跨域问题而白屏
 * Default: NO
 */
@property (nonatomic, assign) BOOL enableFollowRedirect;

- (BOOL)needVerifySSL:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
