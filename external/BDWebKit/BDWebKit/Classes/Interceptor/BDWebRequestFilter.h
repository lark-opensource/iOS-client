//
//  BDWebRequestFilter.h
//  Pods
//
//  Created by wuyuqi.57 on 2021/9/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDWebRequestFilter <NSObject>

- (BOOL)bdw_willBlockRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
