//
//  BDWebViewMonitorFileProvider.h
//  IESWebViewMonitor
//
//  Created by 蔡腾远 on 2019/12/23.
//

#import <Foundation/Foundation.h>
#import <IESWebViewMonitor/BDHybridBaseMonitor.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWebViewMonitorFileProvider : BDHybridBaseMonitor

// 正常接入了新Gecko的会默认注册这些参数，可以不用设置，如果没有注册过gecko，才调用这个注册一下，注意设置的时候需要保证是正常的，否则会覆盖掉原来正常的配置
+ (void)setUpGurdEnvWithAppId:(NSString *)appId appVersion:(NSString *)appVersion cacheRootDirectory:(NSString *)directory deviceId:(NSString *)deviceId;

+ (NSString *)scriptForTimingForWebView:(id)webView domMonitor:(BOOL)domMonitor;

@end

NS_ASSUME_NONNULL_END
