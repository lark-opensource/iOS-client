//
//  CJPayCommonUtil.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import "CJPayCommonUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayProtocolManager.h"
#import <CommonCrypto/CommonDigest.h>

NSString * const kCJPayContentHeightKey = @"cjpay_content_height";

@implementation CJPayCommonUtil

+ (NSString *)createMD5With:(NSString *)str{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result); // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

+ (NSString *)cj_base64:(NSString *)plainString{
    NSData *plainData = [plainString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [plainData base64EncodedStringWithOptions:0];
    return base64String;
}

+ (NSString *)cj_decodeBase64:(NSString *)base64String{
    if (base64String == nil) {
        return @"";
    }
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    return decodedString;
}


+ (NSString*)dictionaryToJson:(NSDictionary *)dic {
    
    __block NSMutableDictionary *mutableDic = [NSMutableDictionary new];
    [dic enumerateKeysAndObjectsUsingBlock:^(id  key, id  obj, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(NSSecureCoding)]) {
            [mutableDic setObject:obj forKey:key];
        }
    }];
    
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[mutableDic copy] ?: @{} options:kNilOptions error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

+ (NSDictionary *)dictionaryFromJsonObject:(id)json {
    if (!json || json == (id)kCFNull) return nil;
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSString class]]) {
        jsonData = [(NSString *)json dataUsingEncoding : NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
        if (![dic isKindOfClass:[NSDictionary class]]) dic = nil;
    }
    return dic;
}

+ (NSString *)arrayToJson:(NSArray *)array {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:kNilOptions error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

+ (nullable NSDictionary *)jsonStringToDictionary:(NSString *)jsonString {
    
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
//        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    if ([dic isKindOfClass:NSDictionary.class]) {
        return dic;
    }
    return nil;
}

+ (NSString *)dateStringFromTimeStamp:(NSTimeInterval )timeStamp
                           dateFormat:(NSString *)dateFormat {
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeStamp];
    
    if (!Check_ValidString(dateFormat)) {
        dateFormat = @"yyyy/MM/dd";
    }
    [dateFormatter setDateFormat:dateFormat];
    return [dateFormatter stringFromDate:date];
}

+ (NSString *)appendParamsToUrl:(NSString *)url params: (NSDictionary *)params{
    if (url == nil || url.length < 1) {
        return @"";
    }
    if (params == nil || params.count < 1) {
        return url;
    }
    NSMutableString *mutableUrl = [NSMutableString stringWithString:url];
    if ([mutableUrl containsString:@"?"]) {
        // do nothing
    } else {
        [mutableUrl appendString:@"?"];
    }
    if ([mutableUrl hasSuffix:@"?"]) {
        // do nothing
    }
    if (![mutableUrl hasSuffix:@"?"] && ![mutableUrl hasSuffix:@"&"]) {
        [mutableUrl appendString:@"&"];
    }
    [params enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSString class]]) {
            NSString *stringValue = [obj stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [mutableUrl appendString:[NSString stringWithFormat:@"%@=%@&", key, stringValue]];
        }
    }];
    if ([mutableUrl hasSuffix:@"&"] && mutableUrl.length > 1) {
        [mutableUrl deleteCharactersInRange:NSMakeRange(mutableUrl.length - 1, 1)];
    }
    return (NSString *)[mutableUrl copy];
}

+ (NSDictionary *)parseScheme:(NSString *)schemeString {
    NSURL *url = [NSURL cj_URLWithString:[schemeString cj_safeURLString]];
    if (!url || ![url isKindOfClass:NSURL.class]) {
        return @{};
    }
    // if url is nil, the following operation will crash
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
    
    __block NSMutableDictionary *schemeDic = [NSMutableDictionary new];
    
    [components.queryItems enumerateObjectsUsingBlock:^(NSURLQueryItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [schemeDic cj_setObject:CJString(obj.value) forKey:CJString(obj.name)];
    }];
    
    return [schemeDic copy];
}

+ (NSString *)generateScheme:(NSDictionary *)schemeDic {
    __block NSString *schemeString = @"sslocal://cjpay/webview?";
    [schemeDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        schemeString = [schemeString stringByAppendingFormat:@"&%@=%@", CJString(key), CJString(obj)];
    }];
    return schemeString;
}

//传入 秒  得到  xx分钟xx秒
+ (NSString *)getMMSSFromSS:(int)totalTime{
    
    NSInteger seconds = @(totalTime).integerValue;
    
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",seconds/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    
    return format_time;
}

// 自定义正数格式(金额的格式转化) 94,862.57 前缀可在所需地方随意添加
+ (NSString *)getMoneyFormatStringFromDouble:(double)number formatString:(nullable NSString *)formatString{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    if (formatString == nil) {
        formatter.positiveFormat = @"###,##0.00";
    }else{
        formatter.positiveFormat = formatString; // 正数格式
    }
    // 注意传入参数的数据长度
    NSString *money = [formatter stringFromNumber:@(number)];
    return money;
}

+ (void)cj_catransactionAction:(void(^)(void))action completion:(void(^)(void))completion {
    [CATransaction setCompletionBlock:^{
        [CJTracker event:@"wallet_rd_catransaction" params:@{
            @"type": @"cj_catransactionAction",
            @"status" : @"completion"
        }];
        CJ_CALL_BLOCK(completion);
    }];
    [CATransaction begin];
    [CJTracker event:@"wallet_rd_catransaction" params:@{
        @"type": @"cj_catransactionAction",
        @"status" : @"action"
    }];
    CJ_CALL_BLOCK(action);
    [CATransaction commit];
}

//+ (void)openLynxPageBySchema:(NSString *)schema
//         completionBlock:(void (^)(CJPayAPIBaseResponse * _Nullable))completion {
//
//    NSMutableDictionary *paramDic = [NSMutableDictionary new];
//    NSMutableDictionary *sdkinfoDic = [NSMutableDictionary new];
//
//    [sdkinfoDic cj_setObject:CJString(schema) forKey:@"schema"];
//    [paramDic cj_setObject:@(98) forKey:@"service"];
//    [paramDic cj_setObject:sdkinfoDic forKey:@"sdk_info"];
//
//    CJ_DECLARE_ID_PROTOCOL(CJPayUniversalPayDeskService);
//    if (objectWithCJPayUniversalPayDeskService) {
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [objectWithCJPayUniversalPayDeskService i_openUniversalPayDeskWithParams:paramDic
//                                                                        withDelegate:[[CJPayAPICallBack alloc] initWithCallBack:^(CJPayAPIBaseResponse * _Nonnull response) {
//                CJ_CALL_BLOCK(completion, response);
//            }]];
//        });
//    } else {
//        CJ_CALL_BLOCK(completion, nil);
//    }
//}

+ (NSString *)replaceNoEncoding:(NSString *)originalStr{
    if (!originalStr) {
        return @"";
    }
    NSMutableString * safeBase64Str = [[NSMutableString alloc]initWithString:CJString(originalStr)];
    safeBase64Str = (NSMutableString * )[safeBase64Str stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    safeBase64Str = (NSMutableString * )[safeBase64Str stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    safeBase64Str = (NSMutableString * )[safeBase64Str stringByReplacingOccurrencesOfString:@"=" withString:@""];
    return safeBase64Str;
}

+ (NSString *)replcaeAutoEncoding:(NSString *)encodingStr{
    NSMutableString * safeBase64Str = [[NSMutableString alloc]initWithString:CJString(encodingStr)];
    safeBase64Str = (NSMutableString * )[safeBase64Str stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
    safeBase64Str = (NSMutableString * )[safeBase64Str stringByReplacingOccurrencesOfString:@"_" withString:@"/"];
    safeBase64Str = (NSMutableString * )[safeBase64Str stringByReplacingOccurrencesOfString:@"" withString:@"="];
    return safeBase64Str;
}

+ (UIImage *)snapViewToImageView:(UIView *)view {
    BOOL opaque = view.isOpaque;
    view.opaque = NO;
    UIImage *snapshotImage = [view btd_snapshotImage];
    view.opaque = opaque;
    return snapshotImage;
}
@end
