//
//  HMDConfigHelper.h
//  Heimdallr
//
//  Created by Nickyo on 2023/5/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDNetworkProvider;

@interface HMDConfigHelper : NSObject

+ (NSDictionary * _Nullable)requestHeaderFromProvider:(id<HMDNetworkProvider> _Nullable)provider;

+ (NSString *)configHeaderKeyForAppID:(NSString *)appID;

@end

NS_ASSUME_NONNULL_END
