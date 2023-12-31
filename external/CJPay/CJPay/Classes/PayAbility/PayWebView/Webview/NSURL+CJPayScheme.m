//
//  NSURL+CJPayScheme.m
//  CJPay
//
//  Created by liyu on 2020/5/29.
//

#import "NSURL+CJPayScheme.h"

@implementation NSURL (CJPayScheme)

- (BOOL)isCJPayWebviewScheme
{
    return ([self.scheme isEqualToString:@"sslocal"]
            && [self.host isEqualToString:@"cjpay"]
            && [self.path isEqualToString:@"/webview"]);
}

- (BOOL)isCJPayHTTPScheme
{
    return ([self.scheme isEqualToString:@"http"]
            || [self.scheme isEqualToString:@"https"]);
}

@end
