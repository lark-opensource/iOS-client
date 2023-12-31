//
//  NSString+BDPExtension.m
//  Timor
//
//  Created by 涂耀辉 on 2018/6/20.
//

#import "NSString+BDPExtension.h"
#import <ECOInfra/BDPUtils.h>
#import <CommonCrypto/CommonDigest.h>
#import "OPAES256Utils.h"
#import "EMAFeatureGating.h"

@implementation NSString (BDPExtension)

- (CGSize)tma_sizeForFont:(UIFont *)font size:(CGSize)size mode:(NSLineBreakMode)lineBreakMode {
    CGSize result;
    if (!font) font = [UIFont systemFontOfSize:12];
    if ([self respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableDictionary *attr = [NSMutableDictionary new];
        attr[NSFontAttributeName] = font;
        if (lineBreakMode != NSLineBreakByWordWrapping) {
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.lineBreakMode = lineBreakMode;
            attr[NSParagraphStyleAttributeName] = paragraphStyle;
        }
        CGRect rect = [self boundingRectWithSize:size
                                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                      attributes:attr context:nil];
        result = rect.size;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        result = [self sizeWithFont:font constrainedToSize:size lineBreakMode:lineBreakMode];
#pragma clang diagnostic pop
    }
    return result;
}

- (CGFloat)tma_widthForFont:(UIFont *)font {
    CGSize size = [self tma_sizeForFont:font size:CGSizeMake(HUGE, HUGE) mode:NSLineBreakByWordWrapping];
    return size.width;
}

- (CGFloat)tma_heightForFont:(UIFont *)font width:(CGFloat)width {
    CGSize size = [self tma_sizeForFont:font size:CGSizeMake(width, HUGE) mode:NSLineBreakByWordWrapping];
    return size.height;
}

- (NSString *)URLEncodedString
{
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                                             (CFStringRef)self,
                                                                                             NULL,
                                                                                             CFSTR(":/?#@!$&'() {}*+="),
                                                                                             kCFStringEncodingUTF8));
    return result;
}

- (NSString*)URLDecodedString
{
    NSString *origin = [self copy];
    NSString *result = (NSString *)CFBridgingRelease(CFURLCreateStringByReplacingPercentEscapesUsingEncoding(kCFAllocatorDefault,
                                                                                                             (CFStringRef)origin,
                                                                                                             CFSTR(""),
                                                                                                             kCFStringEncodingUTF8));
    if (result == nil) {
        return self;
    }
    return result;
}

+ (NSString *)URLEncodedStringPath:(NSString *)path query:(NSDictionary *)query {
    if (BDPIsEmptyString(path)) {
        return nil;
    }
    if (BDPIsEmptyDictionary(query)) {
        return path;
    }
    NSMutableString *queryStr = [NSMutableString string];
    BOOL firstObject = YES;
    for (NSString *key in query) {
        NSObject *value = query[key];
        [queryStr appendFormat:firstObject ? @"%@=%@" : @"&%@=%@", key.URLEncodedString, value.description.URLEncodedString];
        firstObject = NO;
    }
    return [path stringByAppendingFormat:@"?%@", queryStr];
}

- (NSString *)bdp_md5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), digest );

    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];

    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];

    return output;
}

- (NSString *)bdp_fileName {
    unichar kSeparator = '/';
    unichar kDot = '.';
    NSInteger right = self.length; // '.'位置
    NSInteger left = -1; // '/'位置
    NSInteger i = self.length - 1;
    while (i >= 0) {
        if ([self characterAtIndex:i] == kDot) {
            right = i;
        } else if ([self characterAtIndex:i] == kSeparator) {
            left = i;
            break;
        }
        i--;
    }
    NSRange range = NSMakeRange(left + 1, right - left - 1);
    if (range.location + range.length <= self.length) {
        return [self substringWithRange:range];
    }
    return [self copy];
}

- (NSString *)bdp_urlWithoutParmas {
    NSInteger index = [self rangeOfString:@"?"].location;
    if (index != NSNotFound && index <= self.length) { // 干掉所有参数
        return [self substringToIndex:index];
    }
    return [self copy];
}

- (NSString *)bdp_fileUrlAddDirectoryPathIfNeeded {
    if ([self pathExtension].length > 0) { // 非目录
        return [self copy];
    }
    return self.length && [self hasSuffix:@"/"] ? [self copy] : [NSString stringWithFormat:@"%@/", self];
}

- (NSString *)bdp_fileUrlDeleteDirectoryPath {
    return [self hasSuffix:@"/"] ? [self substringToIndex:self.length - 1] : [self copy];
}

- (NSString *)bdp_urlWithoutScheme {
    return [self componentsSeparatedByString:@"://"].lastObject;
}

- (NSString *)bdp_urlScheme {
    NSArray *components = [self componentsSeparatedByString:@"://"];
    if (components && components.count >= 2) {
        return components.firstObject;
    }
    return nil;
}

+ (NSString *)bdp_stringFromBase64String:(NSString *)base64String
{
    NSData *data = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSString *)bdp_subStringForMaxWordLength:(NSUInteger)wordLength withBreak:(BOOL)shouldBreak
{
    NSString *subString = self;
    NSInteger totalLength = 0;
    NSInteger position = 0;
    for (position = 0; position < self.length; ++position) {
        unichar charactor = [self characterAtIndex:position];
        double charactorLenth = 0.f;
        if (isascii(charactor) || isblank(charactor) || isspace(charactor)) {
            charactorLenth = 1;
        } else {
            charactorLenth = 2;
        }
        
        totalLength += charactorLenth;
        if (totalLength > wordLength * 2) {
            break;
        }
    }
    
    if (shouldBreak && totalLength > wordLength * 2) {
        if (totalLength == wordLength * 2 + 2) {
            position -= 1;
        }
        subString = [NSString stringWithFormat:@"%@%@", [self substringToIndex:position], @"..."];
    } else {
        subString = [self substringToIndex:position];
    }
    
    return subString;
}

- (NSString *)bdp_md5String
{
    if(self == nil || [self length] == 0)
    {
        return nil;
    }
    
    const char* input = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (CC_LONG)strlen(input), result);
    
    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [digest appendFormat:@"%02x", result[i]];
    }
    
    return digest;
}

// attribute string utils
+ (NSMutableAttributedString *)bdp_attributedStringWithString:(NSString *)string
                                                     fontSize:(CGFloat)fontSize
                                                   lineHeight:(CGFloat)lineHeight
                                                lineBreakMode:(NSLineBreakMode)lineBreakMode
                                              isBoldFontStyle:(BOOL)isBold
                                              firstLineIndent:(CGFloat)indent
                                                textAlignment:(NSTextAlignment)alignment;
{
    if (!string || ![string isKindOfClass:[NSString class]] || string.length == 0) {
        return [[NSMutableAttributedString alloc] initWithString:@""];
    }
    
    NSDictionary *attributes = [self _bdp_attributesWithFontSize:fontSize lineHeight:lineHeight lineBreakMode:lineBreakMode isBoldFontStyle:isBold firstLineIndent:indent textAlignment:alignment];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    
    [attributedString addAttributes:attributes range:NSMakeRange(0, attributedString.length)];
    return attributedString;
}

- (NSMutableAttributedString *)bdp_attributedStringWithFontSize:(CGFloat)fontSize
                                                     lineHeight:(CGFloat)lineHeight
                                                  lineBreakMode:(NSLineBreakMode)lineBreakMode
                                                isBoldFontStyle:(BOOL)isBold
                                                firstLineIndent:(CGFloat)indent
                                                  textAlignment:(NSTextAlignment)alignment
{
    return [[self class] bdp_attributedStringWithString:self fontSize:fontSize lineHeight:lineHeight lineBreakMode:lineBreakMode isBoldFontStyle:isBold firstLineIndent:indent textAlignment:alignment];
}

#pragma mark - private

+ (NSDictionary *)_bdp_attributesWithFontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode isBoldFontStyle:(BOOL)isBold firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment
{
    UIFont *font = isBold ? [UIFont boldSystemFontOfSize:fontSize] : [UIFont systemFontOfSize:fontSize];
    CGFloat lineHeightMultiple = lineHeight / font.lineHeight;
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineBreakMode = lineBreakMode;
    style.alignment = alignment;
    style.lineHeightMultiple = lineHeightMultiple;
    style.minimumLineHeight = font.lineHeight * lineHeightMultiple;
    style.maximumLineHeight = font.lineHeight * lineHeightMultiple;
    style.firstLineHeadIndent = indent;
    NSDictionary * attributes = @{NSFontAttributeName:font, NSParagraphStyleAttributeName:style};
    return attributes;
}
/**
 整形判断
 */
+ (BOOL)bdp_isPureInt:(NSString *)string {
    NSScanner* scan = [NSScanner scannerWithString:string];
    int val;
    return [scan scanInt:&val] && [scan isAtEnd];
}

+ (NSUInteger)bdp_textLength:(NSString *)text {
    NSUInteger asciiLength = 0;
    for (NSUInteger i = 0; i < text.length; i++) {
        unichar uc = [text characterAtIndex: i];
        asciiLength += isascii(uc) ? 1 : 2;
    }
    NSUInteger unicodeLength = asciiLength;
    return unicodeLength;
}

- (NSData *)hexStringToData {
    NSString *hexString = self;
    const char *chars = [hexString UTF8String];
    int i = 0;
    int len = (int)hexString.length;
    NSMutableData *data = [NSMutableData dataWithCapacity:len/2];

    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;

    while (i<len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    return data;
}

+ (nonnull NSString *)ecoCutDocURL:(NSString * _Nonnull)url {
    // 文档 URL 后缀不允许打印，这里列出常见的文档地址关键词，触发关键词后，会对 URL 进行截断
    NSArray<NSString *> *limitKeywords = @[
        @"doccn", //doc
        @"docus",
        @"doxcn", //docx
        @"doxus",
        @"wikcn", // wiki
        @"wikus",
        @"shtcn", // sheet
        @"shtus",
        @"bmncn", // mindnotes
        @"bmnus",
        @"bascn", // 多维表格
        @"basus"
    ];
    __block NSString *result = url;
    [limitKeywords enumerateObjectsUsingBlock:^(NSString*  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop){
        NSRange range = [url rangeOfString:key];
        if(range.location != NSNotFound) {
            // 若关键字匹配上，进行截断，取 15 个字符可以使关键字全部留下，后续内容被截断
            if(url.length > (range.location + 15)){
                result = [url substringWithRange:NSMakeRange(0, range.location + 15)];
            }
            *stop = YES;
        }
    }];
    BOOL urlencryptLog = [EMAFeatureGating boolValueForKey:@"openplatform.web.lkw.log.url.encrypt" defaultValue:false];
    if (urlencryptLog && result.length != 0) {
        NSArray<NSString *> *fileKeyWords = @[
            @".pdf",
            @".doc",
            @".docx",
            @".ppt",
            @".pptx",
            @".txt",
            @".xls",
            @".xlsx",
            @".mp4",
            @".jpg",
            @".jpeg",
            @".png",
            @".gif",
            @".zip",
            @".svg"
        ];
        [fileKeyWords enumerateObjectsUsingBlock:^(NSString*  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop){
            NSRange range = [result rangeOfString:key];
            if(range.location != NSNotFound) {
                // 若关键字匹配上，直接替换成***
                result = [result stringByReplacingOccurrencesOfString:key withString:@".***"];
                *stop = YES;
            }
        }];
    }
    return result;
}


+ (nullable NSString *)safeURLString:(NSString  * _Nullable)url {
    if (!url || ![url isKindOfClass:[NSString class]] || url.length == 0) {
        return url;
    }
    // URL path 长度限制，减少 ecoCutDocURL 耗时
    // 1024 来源：2021.7~9 月, max(url_path_length) = 584
    //  https://data.bytedance.net/aeolus#/dataQuery?appId=555164&id=1042693434&sid=540532
    url = [url componentsSeparatedByString:@"?"].firstObject;
    url = [url componentsSeparatedByString:@"#"].firstObject;
    if(url.length > 1024) {
        url = [url substringWithRange: NSMakeRange(0, 1024)];
    }
    return [NSString ecoCutDocURL:url];
}

+ (nullable NSString *)safeURL:(NSURL * _Nullable)URL {
    return [NSString safeURLString:URL.absoluteString];
}

- (nullable NSString *)safeURLString {
    return [NSString safeURLString:self];
}

+ (NSString *)safeAES256URLString:(NSString *)url key:(NSString *)key iv:(NSString *)iv {
    if (BDPIsEmptyString(url)) {
        return url;
    }
    return [NSString encryptAES256WithContent:url key:key iv:iv];
}

+ (NSString *)safeAES256URL:(NSURL *)url key:(NSString *)key iv:(NSString *)iv {
    return [NSString safeAES256URLString:url.absoluteString key:key iv:iv];
}

- (NSString *)safeAES256Key:(NSString *)key iv:(NSString *)iv {
    return [NSString safeAES256URLString:self key:key iv:iv];
}

+ (nullable NSString *)encryptAES256WithContent:(NSString *)content key:(NSString *)key iv:(NSString *)iv {
    if (BDPIsEmptyString(content) || BDPIsEmptyString(key)) {
        return nil;
    }
    return [OPAES256Utils encryptWithContent:content key:key iv:iv];
}

+ (nullable NSString *)decryptAES256WithContent:(NSString *)content key:(NSString *)key iv:(NSString *)iv {
    if (BDPIsEmptyString(content) || BDPIsEmptyString(key)) {
        return nil;
    }
    return [OPAES256Utils decryptWithContent:content key:key iv:iv];
}

@end
