//
//  HMDURLManager.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/23.
//

#import <Foundation/Foundation.h>
#import "HMDURLProvider.h"

/// 模块网络管理
@interface HMDURLManager : NSObject

+ (NSString * _Nullable)URLWithProvider:(id<HMDURLProvider> _Nonnull)provider
                               forAppID:(NSString * _Nullable)appID;
+ (NSString * _Nullable)URLWithProvider:(id<HMDURLProvider> _Nonnull)provider
                               tryIndex:(NSUInteger)index
                               forAppID:(NSString * _Nullable)appID;

+ (NSString * _Nullable)URLWithHostProvider:(id<HMDURLHostProvider> _Nonnull)hostProvider
                               pathProvider:(id<HMDURLPathProvider> _Nonnull)pathProvider
                                   forAppID:(NSString * _Nullable)appID;
+ (NSString * _Nullable)URLWithHostProvider:(id<HMDURLHostProvider> _Nonnull)hostProvider
                               pathProvider:(id<HMDURLPathProvider> _Nonnull)pathProvider
                                   tryIndex:(NSUInteger)index
                                   forAppID:(NSString * _Nullable)appID;

+ (NSArray<NSString *> * _Nullable)hostsWithProvider:(id<HMDURLHostProvider> _Nonnull)provider
                                            forAppID:(NSString * _Nullable)appID;

@end
