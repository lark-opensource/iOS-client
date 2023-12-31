//
//  NSString+CJExtension.m
//  AFNetworking
//
//  Created by jiangzhongping on 2018/8/17.
//

#import "NSString+CJPay.h"

#import <CommonCrypto/CommonCrypto.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import "CJPayMonitor.h"
#import "UIFont+CJPay.h"
#import "UIColor+CJPay.h"
#import "NSArray+CJPay.h"

@implementation NSString (CJPay)

- (CGSize)cj_sizeWithFont:(UIFont*)font maxSize:(CGSize)size {
    NSDictionary *attrs = @{ NSFontAttributeName: font};
    return [self boundingRectWithSize:size
                              options:NSStringDrawingUsesLineFragmentOrigin
                           attributes:attrs context:nil].size;
}

- (CGSize)cj_sizeWithFont:(UIFont*)font width:(CGFloat)width {
    return [self btd_sizeWithFont:font width:width];
}

- (NSString *)cj_URLEncode {
    return [self urlEncodeUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
                                                                                 NULL,
                                                                                 (__bridge CFStringRef)self,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                                                 CFStringConvertNSStringEncodingToEncoding(encoding)));
}

- (NSString *)cj_md5String {
    
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    const char *str = [data bytes];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)data.length, result);
    
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [hash appendFormat:@"%02X", result[i]];
    }
    return [hash lowercaseString];
}

- (NSData *)base64DecodeData {
    return [[NSData alloc] initWithBase64EncodedString:self options:0];
}

- (NSData*) hexToBytes {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= self.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [self substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}
    

- (NSString *_Nullable)cj_matchedByRegex:(NSString *_Nullable)pattern forcedMatchedFromPrefix:(BOOL)isPrefix
{
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (error) {
        return nil;
    }
    
    NSRange matchedRange = [regex rangeOfFirstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    if (matchedRange.location != NSNotFound && (!isPrefix || matchedRange.location == 0)) {
        return [self substringWithRange:matchedRange];
    } else {
        return nil;
    }
}

- (NSString *_Nullable)cj_removeBookNum {
    return [self cj_matchedByRegex:@"[^\\《^\\》]+" forcedMatchedFromPrefix:NO];
}

- (NSString *_Nullable)cj_remove:(NSString *_Nonnull)str {
    if (str.length <= 0) {
        return self;
    }
    return [self stringByReplacingOccurrencesOfString:str withString:@""];
}

- (NSString *_Nullable)cj_noSpace {
    return [self cj_remove:@" "];
}

- (nullable NSDictionary *)cj_toDic {
    if (self == nil) {
        return nil;
    }
    NSData *jsonData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
        return nil;
    }
    return dic;
}

- (NSString *)cj_base64EncodeString

{

NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];

return [data base64EncodedStringWithOptions:0];

}

+ (NSString *)cj_joinedWithSubStrings:(NSString *)firstStr,...NS_REQUIRES_NIL_TERMINATION {
    NSMutableArray *array = [NSMutableArray new];
    va_list args;
    if(firstStr) {
        [array addObject:firstStr];
        va_start(args, firstStr);
        id obj;
        while ((obj = va_arg(args, NSString* ))) {
            [array addObject:obj];
        }
        va_end(args);
    }
    return [array componentsJoinedByString:@""];
}

- (NSDictionary *)cj_urlQueryParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:self];
    if (urlComponents) {
        [urlComponents.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.value && obj.name) {
                params[obj.name] = obj.value;
            }
        }];
    }
    return [params copy];
}

- (NSString *_Nullable)cj_urlPath {
    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithString:self];
    return urlComponents.path;
}

- (NSString *)cj_safeURLString {
    if ([NSURL URLWithString:self]) {
        return self;
    }
    
    [CJMonitor trackService:@"wallet_rd_unsafeURLString" extra:@{@"url" : self ?: @"UNKNOWN"}];
    
    // 对 url 进行百分比编码
    NSString *encodedString = [self stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    return encodedString;
}

- (NSString *)cj_replaceUnicode {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [[NSString alloc] initWithData:data encoding:NSNonLossyASCIIStringEncoding];
}

- (NSMutableAttributedString *)attributedStringWithDollarSeparated { // "购物快人一步 $|$ 百万保险保驾护航" 转换为 " 购物快人一步 | 百万保险保驾护航"
    if (![self containsString:@"$"]) {
        return [[NSMutableAttributedString alloc] initWithString:self];
    }
    NSArray *arr = [self componentsSeparatedByString:@"$"];
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    NSDictionary *textAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor cj_161823WithAlpha:0.5],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSDictionary *lineAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:12],
                                     NSForegroundColorAttributeName : [UIColor cj_colorWithHexString:@"505158" alpha:0.2],
                                     NSParagraphStyleAttributeName : paraStyle};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[arr cj_objectAtIndex:0] ?: @"" attributes:textAttributes];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:1] ?: @"" attributes:lineAttributes]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:2] ?: @"" attributes:textAttributes]];
    return attributedString;
}

@end
