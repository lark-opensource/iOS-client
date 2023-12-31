//
//  BDWebInterceptor+Private.h
//  BDWebKit
//
//  Created by li keliang on 2020/4/23.
//

#import "BDWebInterceptor.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDWebInterceptor (Private)

- (nullable Class<BDWebURLSchemeTaskHandler>)schemaHandlerClassWithURLRequest:(NSURLRequest *)request
                                                                      webview:(nullable WKWebView *)webview;

- (nullable NSArray<Class<BDWebRequestDecorator>> *)bdw_requestDecorators;

@end

NS_ASSUME_NONNULL_END
