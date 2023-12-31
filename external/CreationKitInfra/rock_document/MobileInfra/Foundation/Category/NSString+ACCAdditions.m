//
//  NSString+ACCAdditions.m
//  CameraClient
//
//  Created by Liu Deping on 2019/12/4.
//

#import "NSString+ACCAdditions.h"
#import "NSData+ACCAdditions.h"
#import <CoreText/CoreText.h>
#import <CreativeKit/ACCMacros.h>

@implementation NSString (ACCAdditions)

- (NSString *)acc_md5String
{
    return [[self dataUsingEncoding:NSUTF8StringEncoding] acc_md5String];
}

- (CGFloat)acc_widthWithFont:(UIFont *)font height:(CGFloat)maxHeight
{
    CGRect rect = [self boundingRectWithSize:CGSizeMake(MAXFLOAT, maxHeight)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{ NSFontAttributeName : font }
                                     context:nil];
    CGFloat width = ceil(rect.size.width);
    return width;
}

- (CGFloat)acc_heightWithFont:(UIFont *)font width:(CGFloat)maxWidth
{
    return [self acc_sizeWithFont:font width:maxWidth].height;
}

- (CGSize)acc_sizeWithFont:(UIFont *)font width:(CGFloat)maxWidth {
    return [self acc_sizeWithFont:font width:maxWidth maxLine:0];
}

- (CGSize)acc_sizeWithFont:(UIFont *)font width:(CGFloat)maxWidth maxLine:(NSInteger)maxLine {
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.minimumLineHeight = font.lineHeight;
    style.maximumLineHeight = font.lineHeight;
    CGFloat maxHeight = maxLine ? maxLine * font.lineHeight : CGFLOAT_MAX;
    CGRect rect = [self boundingRectWithSize:CGSizeMake(maxWidth, maxHeight)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{NSFontAttributeName:font, NSParagraphStyleAttributeName:style}
                                     context:nil];
    return CGSizeMake(ceil(rect.size.width), ceil(rect.size.height));
}

- (NSInteger)acc_lineCountWithFont:(UIFont *)font
                    paragraphStyle:(NSMutableParagraphStyle *)paragraphStyle
             appendOtherAttributes:(void (^)(NSMutableDictionary<NSAttributedStringKey,id> * _Nonnull))appendBlock
                          maxWidth:(CGFloat)maxWidth{
    
    if (self.length == 0 || !font || maxWidth <= ACC_FLOAT_ZERO ) {
        return 0;
    }
    
    NSMutableDictionary <NSAttributedStringKey, id> *attributes = @{NSFontAttributeName : font}.mutableCopy;
    if (paragraphStyle) {
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    }
    
    if (appendBlock != nil) {
        appendBlock(attributes);
    }
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:self attributes:[attributes copy]];
    
    CTFramesetterRef framesetterRef = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGPathAddRect(pathRef, NULL ,CGRectMake(0 , 0 , maxWidth, CGFLOAT_MAX));
    
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetterRef, CFRangeMake(0, 0), pathRef, NULL);
    
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frameRef);
    NSInteger numberOfLines = lines.count;
    
    if (frameRef != NULL) {
       CFRelease(frameRef);
    }
    
    if (pathRef != NULL) {
        CGPathRelease(pathRef);
    }
    
    if (framesetterRef != NULL) {
        CFRelease(framesetterRef);
    }
    
    return numberOfLines;
}

//- (NSString *)acc_stringByURLEncode
//{
//    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
//                                                                                 (CFStringRef)self,
//                                                                                 NULL, // characters to leave unescaped
//                                                                                 CFSTR(":!*();@/&?+$,='"),
//                                                                                 kCFStringEncodingUTF8);
//}
//
//- (NSString *)acc_stringByURLDecode
//{
//    CFStringEncoding en = CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding);
//    NSString *decoded = [self stringByReplacingOccurrencesOfString:@"+"
//                                                        withString:@" "];
//    decoded = (__bridge_transfer NSString *)
//    CFURLCreateStringByReplacingPercentEscapesUsingEncoding(
//                                                            NULL,
//                                                            (__bridge CFStringRef)decoded,
//                                                            CFSTR(""),
//                                                            en);
//    return decoded;
//}

- (id)acc_jsonValueDecoded
{
    NSError *error = nil;
    return [self acc_jsonValueDecoded:&error];
}

- (id)acc_jsonValueDecoded:(NSError *__autoreleasing *)error
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data acc_jsonValueDecoded:error];
}

- (nullable id)acc_ContentJsonDecoded
{
    NSString *decodedString = [NSString stringWithFormat:@"[\"%@\"]",self];
    NSData *data = [decodedString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return nil;
    }
    id decoded = [data acc_jsonValueDecoded:nil];
    if ([decoded isKindOfClass:[NSArray class]]) {
        NSArray *decodeArrray = [(NSArray *)decoded mutableCopy];
        if (decodeArrray.count <= 0) {
            return nil;
        }
        return [decodeArrray[0] acc_jsonValueDecoded:nil];
    }
    return nil;
}

- (NSArray *)acc_jsonArray
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data acc_jsonArray];
}

- (NSDictionary *)acc_jsonDictionary
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data acc_jsonDictionary];
}

- (NSArray *)acc_jsonArray:(NSError * _Nullable __autoreleasing *)error
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data acc_jsonArray:error];
}

- (NSDictionary *)acc_jsonDictionary:(NSError * _Nullable __autoreleasing *)error
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data acc_jsonDictionary:error];
}


- (BOOL)acc_isRTLString
{
    return [self hasPrefix:@"\u202B"];
}

- (BOOL)acc_isLTRString
{
    return [self hasPrefix:@"\u202A"];
}

- (NSString *)acc_RTLString
{
    if ([self acc_isRTLString] || [self acc_isLTRString]) {
        return self;
    }
    return [NSString stringWithFormat:@"\u202B%@\u202C", self];
}

- (NSString *)acc_LTRString
{
    if ([self acc_isRTLString] || [self acc_isLTRString]) {
        return self;
    }
    return [NSString stringWithFormat:@"\u202A%@\u202C", self];
}

- (NSString *)accrtl_FSIString
{
    return [NSString stringWithFormat:@"\u2068%@\u2069", self];
}

#pragma mark - write

- (BOOL)acc_writeToURL:(NSURL *)url atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError **)error
{
    NSError *innerError;
    BOOL writeSuccess = [self writeToURL:url atomically:useAuxiliaryFile encoding:enc error:&innerError];
    if (!writeSuccess && innerError) {
        if ([innerError.domain isEqual:NSCocoaErrorDomain] && innerError.code == NSFileWriteUnknownError) {
            writeSuccess = [self writeToURL:url atomically:NO encoding:enc error:&innerError];
            if (writeSuccess) {
                innerError = nil;
            }
            if (error) {
                *error = innerError;
            }
        }
    }
    return writeSuccess;
}

- (BOOL)acc_writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile encoding:(NSStringEncoding)enc error:(NSError **)error
{
    NSError *innerError;
    BOOL writeSuccess = [self writeToFile:path atomically:useAuxiliaryFile encoding:enc error:&innerError];
    if (!writeSuccess && innerError) {
        if ([innerError.domain isEqual:NSCocoaErrorDomain] && innerError.code == NSFileWriteUnknownError) {
            writeSuccess = [self writeToFile:path atomically:NO encoding:enc error:&innerError];
            if (writeSuccess) {
                innerError = nil;
            }
            if (error) {
                *error = innerError;
            }
        }
    }
    return writeSuccess;
}

- (NSString *)acc_urlEncodedString
{
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[[NSCharacterSet characterSetWithCharactersInString:@" &=\"#%/:<>?@[\\]^`{|}"] invertedSet]];
}

- (NSString *)acc_urlDecodedString
{
    return [self stringByRemovingPercentEncoding];
}

- (uint32_t)acc_argbColorHexValue
{
    if (self.length <= 8) {
        return 0;
    }
    uint32_t argbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setScanLocation:2]; // bypass '0x' character
    [scanner scanHexInt:&argbValue];
    return argbValue;
}

+ (NSString *)acc_colorHexStringFrom:(uint32_t)hexValue
{
    return [NSString stringWithFormat:@"%02x", hexValue];
}

- (BOOL)acc_containsNumberOnly
{
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [self rangeOfCharacterFromSet:notDigits].location == NSNotFound;
}



@end
