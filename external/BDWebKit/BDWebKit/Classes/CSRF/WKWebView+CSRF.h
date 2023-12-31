//
//  WKWebView+CSRF.h
//
//  Created by huangzhongwei on 2021/2/22.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef NSString*(^BDCustomUARegister)(NSString*);
@interface WKWebView (CSRF)
+(void)bd_tryFixCSRF:(BDCustomUARegister)block;
+(NSString*)csrfUserAgent;
@end

NS_ASSUME_NONNULL_END
