//
//  IWKPluginUIDelegateProxy.h
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IWKPluginUIDelegateProxy : NSObject<WKUIDelegate>

@property (nonatomic, weak) id<WKUIDelegate> proxy;
@property (nonatomic, weak) WKWebView *webView;

@end

NS_ASSUME_NONNULL_END
