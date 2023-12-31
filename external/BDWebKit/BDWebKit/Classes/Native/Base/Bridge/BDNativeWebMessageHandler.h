//
//  BDNativeWebMessageHandler.h
//  BDNativeWebView
//
//  Created by liuyunxuan on 2019/7/8.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
NS_ASSUME_NONNULL_BEGIN

@protocol BDNativeWebMessageHandlerDelegate <NSObject>

- (void)bdNativeUserContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end

@interface BDNativeWebMessageHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic, weak) id<BDNativeWebMessageHandlerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
