//
//  BDWebURLSchemeProtocolClass.h
//  Pods
//
//  Created by bytedance on 4/14/22.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@protocol BDWebURLSchemeTask;

NS_ASSUME_NONNULL_BEGIN

@protocol BDWebURLSchemeProtocolClass <NSObject>

/*!
    @method canInitWithSchemeTask:
    @abstract This method determines whether this protocol can handle
    the given schemeTask.
    @param schemeTask A schemeTask to inspect.
    @result YES if the protocol can handle the given task, NO if not.
*/
+ (BOOL)canInitWithSchemeTask:(id<BDWebURLSchemeTask>)schemeTask;

@optional

/*!
    @method startLoading
    @abstract Starts protocol-specific loading of a request.
    @param webView current webview.
    @discussion When this method is called, the protocol implementation
    should start loading a request.
*/
- (void)startLoadingWithWebView:(WKWebView * _Nullable)webView;

@end

NS_ASSUME_NONNULL_END
