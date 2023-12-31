//
//  NSMutableURLRequest+Signature.m
//  OneKit
//
//  Created by 朱元清 on 2021/1/13.
//
#import "NSMutableURLRequest+OKSignature.h"
#import "OKMARSAuthHelper.h"
#import "OKApplicationInfo.h"

// 访问MARS网关的请求，需要通过下面的API签名。
// doc: https://bytedance.feishu.cn/docs/doccnNTm3UswkV0BOovnPtI3cXe
@implementation NSMutableURLRequest (OKSignature)

- (void)ok_autoSign {
    NSString *AK = [OKApplicationInfo sharedInstance].accessKey;
    NSString *SK = [OKApplicationInfo sharedInstance].secretKey;
    [self ok_signWithAK:AK SK:SK];
}

/*! 根据传入的AK,SK参数来签名
 * 设置以下的HTTPHeaderFields，以满足MARS请求签名要求
 * 字段算法
 *   X-mars-date：{kDate}
 *   Authorization: HMAC-SHA256 Credential={AppKey},SignedHeaders={SignedHeaderNames},Signature={Signature}
 * @param AK AppKey
 * @param SK AppSecretKey
 */
- (void)ok_signWithAK:(NSString *)AK SK:(NSString *)SK {
    if (!AK || !SK) {
        return;
    }
    NSString *kDate = [OKMARSAuthHelper x_mars_date];
    NSString *kSign = [OKMARSAuthHelper HmacSHA256WithKey:SK data:kDate];
    // add Header Fields
    [self setValue:kDate forHTTPHeaderField:@"X-mars-date"];
    
    // 签名 Header Fields
    NSMutableString *signedHeaders = [NSMutableString new],
                    *headerToSign = [NSMutableString new];
    NSDictionary <NSString *, NSString *> *httpHeaderFields = [self allHTTPHeaderFields];
    for (NSString *headerFieldKey in httpHeaderFields) {
        NSString *headerFieldValue = httpHeaderFields[headerFieldKey];
        if ([headerFieldKey.lowercaseString isEqualToString:@"x-mars-date"]) {
            [signedHeaders appendString:headerFieldKey.lowercaseString];
            [signedHeaders appendString:@";"];
            
            headerFieldValue = [headerFieldValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            [headerToSign appendString:[NSString stringWithFormat:@"%@:%@", headerFieldKey.lowercaseString, headerFieldValue]];
            [headerToSign appendString:@"\n"];
        }
    }
    
    // 签名 HTTP body
    NSString *requestBodyMd5 = [OKMARSAuthHelper md5FromData:[self HTTPBody]];
    
    // 生成签名 {signature}
    NSString *stringToSign = [headerToSign stringByAppendingString:requestBodyMd5];
    NSString *signature = [OKMARSAuthHelper HmacSHA256WithKey:kSign data:stringToSign];
    
    NSString *authorizationHeaderField = [NSString stringWithFormat:@"HMAC-SHA256 Credential=%@,SignedHeaders=%@,Signature=%@", AK, signedHeaders, signature];
    
    [self setValue:authorizationHeaderField forHTTPHeaderField:@"Authorization"];
}

@end
