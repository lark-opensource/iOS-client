//
//  BDWebCsrfPlugin.m
//
//  Created by huangzhongwei on 2021/2/22.
//

#import "BDWebCsrfPlugin.h"

@interface BDWebCsrfPlugin ()
@property (nonatomic, strong) BDCustomUARegister regBlock;
@end


@implementation BDWebCsrfPlugin

-(instancetype)initWithUARegister:(BDCustomUARegister)block {
    if(self = [super init]){
        self.regBlock = block;
    }
    return self;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration{
    
    if (self.regBlock) {
        webView.customUserAgent = self.regBlock([WKWebView csrfUserAgent]);
    }
    
    return IWKPluginHandleResultContinue;
}

@end




