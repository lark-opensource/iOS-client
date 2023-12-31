//
//  BDWebHTTPCachePolicy.h
//  Pods
//
//  Created by bytedance on 3/23/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    BDWebHTTPCachePolicyUseAppSetting,
    BDWebHTTPCachePolicyDisableCache,
    BDWebHTTPCachePolicyEnableCache
}BDWebHTTPCachePolicy;

NS_ASSUME_NONNULL_END
