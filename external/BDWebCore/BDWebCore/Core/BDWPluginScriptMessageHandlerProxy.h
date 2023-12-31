//
//  BDWPluginScriptMessageHandlerProxy.h
//  BDWebCore
//
//  Created by 李琢鹏 on 2020/1/16.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDWPluginScriptMessageHandlerProxy : NSObject<WKScriptMessageHandler>

@property(nonatomic, strong) id<WKScriptMessageHandler> realHandler;
@property(nonatomic, weak) WKWebView *webView;

@end

NS_ASSUME_NONNULL_END
