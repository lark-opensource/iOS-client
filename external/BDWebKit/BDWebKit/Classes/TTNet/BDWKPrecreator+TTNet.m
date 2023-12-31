//
//  BDWKPrecreator+TTNet.m
//  BDWebKit
//
//  Created by Nami on 2019/11/27.
//

#import "BDWKPrecreator+TTNet.h"
#import <WebKit/WebKit.h>
#import "BDWebInterceptor.h"
#import "BDWebViewSchemeTaskHandler.h"
#import "WKWebView+BDInterceptor.h"

@implementation BDWKPrecreator (TTNet)

+ (instancetype)ttnetPrecreator {
    if (@available(iOS 12.0, *)) {
        [[BDWebInterceptor sharedInstance] registerCustomURLSchemaHandler:BDWebViewSchemeTaskHandler.class];
    }
    static BDWKPrecreator *provider;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        provider = [[BDWKPrecreator alloc] init];
        provider.generateHandler = ^WKWebView * _Nonnull(WKWebViewConfiguration * _Nonnull configuration) {
            WKWebViewConfiguration *config = configuration;
            if (config) {
                
            } else {
                config = [[WKWebViewConfiguration alloc] init];
            }
            if (@available(iOS 12.0, *)) {
                config.bdw_enableInterceptor = YES;
            }
            return [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        };
    });
    return provider;
}

@end
