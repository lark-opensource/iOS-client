//
//  TTNetworkManager+IESWKAddition.h
//  BDJSBridgeAuthManager-CN-Core
//
//  Created by bytedance on 2020/8/26.
//

#import <TTNetworkManager/TTNetworkManager.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTNetworkManager (IESWKAddition)

- (TTHttpTask *)requestWithURL:(NSString *)url method:(NSString *)method params:(NSDictionary *)params callback:(TTNetworkJSONFinishBlock)callback;

@end

NS_ASSUME_NONNULL_END
