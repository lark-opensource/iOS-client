//
//  BDWebCsrfPlugin.h
//
//  Created by huangzhongwei on 2021/2/22.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <BDWebCore/IWKPluginObject.h>
#import "WKWebView+CSRF.h"
NS_ASSUME_NONNULL_BEGIN

@interface BDWebCsrfPlugin : IWKPluginObject <IWKClassPlugin>
-(instancetype)initWithUARegister:(BDCustomUARegister)block;
@end

NS_ASSUME_NONNULL_END
