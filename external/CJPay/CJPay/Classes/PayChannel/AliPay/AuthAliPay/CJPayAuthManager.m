//
//  CJPayAuthManager.m
//  CJPay
//
//  Created by 王新华 on 3/2/20.
//

#import "CJPayAuthManager.h"
#import "CJPaySDKMacro.h"
#import <AlipaySDK/AlipaySDK.h>
#import "CJPayPrivacyMethodUtil.h"

@interface CJPayAuthManager()

@property (nonatomic, copy) NSString *authAliPayScheme;
@property (nonatomic, assign) BOOL isInAuthing;
@property (nonatomic, copy) CompletionBlock completionBlock;

@end

@implementation CJPayAuthManager

+ (instancetype)shared {
    static CJPayAuthManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayAuthManager new];
    });
    return manager;
}

- (NSString *)authAliPayScheme {
    if (_authAliPayScheme && _authAliPayScheme.length > 0) {
        return _authAliPayScheme;
    } else {
        NSString *alipayScheme = @"";
        NSArray *URLTypeArray = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleURLTypes"];
        for (NSDictionary *anURLType in URLTypeArray) {
            if ([@"alipayShare" isEqualToString:[anURLType objectForKey:@"CFBundleURLName"]]) {
                alipayScheme = [[anURLType objectForKey:@"CFBundleURLSchemes"] objectAtIndex:0];
                break;
            }
        }
        return alipayScheme;
    }
}

- (BOOL)canProcessURL:(NSURL *)url {
    if ([url.absoluteString hasPrefix:[NSString stringWithFormat:@"%@://%@", self.authAliPayScheme, @"safepay"]]) {
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            // 如果App被杀死就不在调用了
            CJ_CALL_BLOCK(self.completionBlock,resultDic);
        }];
        return YES;
    }
    return NO;
}

- (void)registerAuthAliPayScheme:(NSString *)scheme {
    _authAliPayScheme = scheme;
}

- (void)authAliPay:(NSString *)infoStr callback:(void (^)(NSDictionary * _Nonnull))callback {

    CJPayLogAssert(self.authAliPayScheme, @"为配置alipay授权的scheme，请通过registerAuthAliPayScheme进行注册");
    self.completionBlock = callback;
    [CJPayPrivacyMethodUtil injectCert:@"bpea-cjpayauth_ap_authap"];
    [[AlipaySDK defaultService] auth_V2WithInfo:infoStr fromScheme:self.authAliPayScheme callback:^(NSDictionary *resultDic) {
        CJ_CALL_BLOCK(self.completionBlock,resultDic);
    }];
    [CJPayPrivacyMethodUtil clearCert];
}

@end
