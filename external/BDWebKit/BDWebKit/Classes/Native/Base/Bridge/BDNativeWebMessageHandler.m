//
//  BDNativeWebMessageHandler.m
//  BDNativeWebView
//
//  Created by liuyunxuan on 2019/7/8.
//

#import "BDNativeWebMessageHandler.h"

@implementation BDNativeWebMessageHandler

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (void)dealloc
{
    
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([self.delegate respondsToSelector:@selector(bdNativeUserContentController:didReceiveScriptMessage:)]) {
        [self.delegate bdNativeUserContentController:userContentController didReceiveScriptMessage:message];
    }
}

@end
