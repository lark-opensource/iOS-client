//
//  BDWebRequestDecorator.h
//  BDWebKit
//
//  Created by yuanyiyang on 2020/5/11.
//

#import <Foundation/Foundation.h>
#import <BDWebKit/BDWebURLSchemeTaskHandler.h>
#import <BDWebKit/BDWebURLProtocolTask.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDWebRequestDecorator <NSObject>

- (NSURLRequest *)bdw_decorateRequest:(NSURLRequest *)request;

@optional

- (void)bdw_decorateSchemeTask:(id<BDWebURLSchemeTask>)schemeTask;

- (void)bdw_decorateURLProtocolTask:(id<BDWebURLProtocolTask>)urlProtocolTask;

@end

NS_ASSUME_NONNULL_END
