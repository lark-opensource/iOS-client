//
//  TTRexxarWebViewAdapter.h
//  TTBridgeUnify
//
//  Created by lizhuopeng on 2019/3/29.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@class TTWebViewBridgeEngine;

@interface WKWebView (TTRexxarAdapter)

@property(nonatomic, strong) NSURL *tt_commitURL;

- (void)tt_enableRexxarAdapter __deprecated_msg("RexxarAdapter is enabled by default. This method is no longer needed!");

@end

@interface TTRexxarWebViewAdapter : NSObject

+ (BOOL)handleBridgeRequest:(NSURLRequest *)request engine:(TTWebViewBridgeEngine *)engine;
+ (void)fireEvent:(NSString *)eventName data:(NSDictionary *)data engine:(TTWebViewBridgeEngine *)engine  __deprecated_msg("Please use -[TTBridgeEngine fireEvent:::].");

@end

NS_ASSUME_NONNULL_END
