//
//  IWKPluginDelegateProxy.h
//  BDWebCore
//
//  Created by li keliang on 2019/7/19.
//

#import <UIKit/UIKit.h>

@interface IWKPluginDelegateProxy : NSObject<UIWebViewDelegate>

@property (nonatomic, weak) id<UIWebViewDelegate> proxy;
@property (nonatomic, weak) UIWebView *webView;

@end
