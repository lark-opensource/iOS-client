//
//  HMDURLProvider.h
//  Heimdallr
//
//  Created by Nickyo on 2023/8/2.
//

#ifndef HMDURLProvider_h
#define HMDURLProvider_h

#import <Foundation/Foundation.h>

@protocol HMDURLHostProvider <NSObject>

@required
/// 是否加密
- (BOOL)shouldEncrypt;

@optional
/// 配置主机列表
- (NSArray<NSString *> * _Nullable)URLHostProviderConfigHosts:(NSString * _Nullable)appID;
/// 注入主机列表
- (NSArray<NSString *> * _Nullable)URLHostProviderInjectedHosts:(NSString * _Nullable)appID;
/// 默认主机列表
- (NSArray<NSString *> * _Nullable)URLHostProviderDefaultHosts:(NSString * _Nullable)appID;

@end

@protocol HMDURLPathProvider <NSObject>

@optional
/// 请求路径
- (NSString * _Nullable)URLPathProviderURLPath:(NSString * _Nullable)appID;

@end

@protocol HMDURLProvider <HMDURLHostProvider, HMDURLPathProvider>

@end

#endif /* HMDURLProvider */
