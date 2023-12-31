//
//  BDWebViewURLProtocolClient.h
//  ByteWebView
//
//  Created by Lin Yong on 2019/2/27.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <BDWebKit/BDWebURLSchemeTask.h>


API_AVAILABLE(ios(11.0))
@interface BDWebViewURLProtocolClient : NSObject <NSURLProtocolClient>

- (instancetype)initWithWebView:(WKWebView *) webView schemeTask:(id<BDWebURLSchemeTask>)schemeTask;

@property (nonatomic, assign) BOOL isStopped;

@end
