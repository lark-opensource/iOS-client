//
//  AWEWebViewChannelInterceptor.h
//  AWEWebView
//
//  Created by 01 on 2020/3/22.
//


#import <Foundation/Foundation.h>
#import <BDWebKit/IESFalconManager.h>
#import <BDWebKit/IESFalconGurdInterceptionDelegate.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * _Nonnull(^AWEFalconWebViewGetChannelBlock)(NSURL *requestURL);
typedef NSString * _Nonnull(^AWEFalconWebViewGetAccessKeyBlock)(NSURL *requestURL);

@interface AWEWebViewChannelInterceptor : NSObject <IESFalconCustomInterceptor>

@property(nonatomic, assign) BOOL enable; // 拦截器开关

- (instancetype)initWithAccessKey:(NSString *)accessKey
                     channelBlock:(AWEFalconWebViewGetChannelBlock)channelBlock;

- (instancetype)initWithAccessKeyBlock:(AWEFalconWebViewGetAccessKeyBlock)accessKeyBlock
                          channelBlock:(AWEFalconWebViewGetChannelBlock)channelBlock;

- (void)registerInterceptionDelegate:(id<IESFalconGurdInterceptionDelegate>)gurdInterceptionDelegate;

- (void)unregisterInterceptionDelegate:(id<IESFalconGurdInterceptionDelegate>)gurdInterceptionDelegate;

@end

NS_ASSUME_NONNULL_END
