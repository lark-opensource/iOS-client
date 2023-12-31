//
//  CJPayRecogFacePluginImpl.m
//  Pods
//
//  Created by 王新华 on 2021/9/9.
//

#import "CJPayRecogFacePluginImpl.h"
#import "CJPaySDKHTTPRequestSerializer.h"
#import "CJPaySDKMacro.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayProtocolManager.h"
#import "CJPayRequestCommonConfiguration.h"

@interface CJPayRecogFacePluginImpl()<CJPaySDKHTTPRequestCustomHeaderProtocol>

@end

@implementation CJPayRecogFacePluginImpl

CJPAY_REGISTER_PLUGIN({
    [CJPayRequestCommonConfiguration appendCustomHeaderProtocol:self];
})

+ (void)appendCustomRequestHeaderFor:(TTHttpRequest *)httpRequest {
    [httpRequest setValue:[CJPayRecogFacePluginImpl commonCJPaySDKInfoString] forHTTPHeaderField:@"X-Cjpay-Sdk-Info"];
}

+ (NSString *)commonCJPaySDKInfoString {
    
    NSDictionary *dic = @{
        @"version": CJString([CJSDKParamConfig defaultConfig].version),
        @"features": @{
            @"login_sdk": @"1", // 统一登录 SDK
            @"living_check_pay" : [self p_getFaceRecogSupportStr] // 活体验证
        }
    };
    
    NSString *jsonString = [CJPayCommonUtil dictionaryToJson:dic];
    NSString *urlEncodeString = [jsonString cj_URLEncode];
    return CJString(urlEncodeString);
}


+ (NSString *)p_getFaceRecogSupportStr {
    NSString *livingCheckPay = @"0";
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayFaceLivenessProtocol)) {
        livingCheckPay = @"1";
    }
    return livingCheckPay;
}

@end
