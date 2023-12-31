//
//  BDUGShareBaseUtil.m
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/11/3.
//

#import "BDUGShareBaseUtil.h"

@implementation BDUGShareBaseUtil

+ (NSUInteger)lengthOfWords:(NSString *)string {
    NSUInteger chCounts = 0, blankCounts = 0, zhCounts = 0;
    for (NSUInteger i = 0; i < [string length]; i++) {
        unichar ch = [string characterAtIndex:i];
        if (isblank(ch)  || isspace(ch)) {
            blankCounts++;
        } else if (isascii(ch)) {
            chCounts++;
        } else {
            zhCounts++;
        }
    }
    if (chCounts == 0 && zhCounts == 0) return 0;
    return (zhCounts + (int)ceilf((float)(blankCounts + chCounts)/2.f));
}

+ (UIWindow *)mainWindow
{
    UIWindow * window = nil;
    if ([[UIApplication sharedApplication].delegate respondsToSelector:@selector(window)]) {
        window = [[UIApplication sharedApplication].delegate window];
    }
    if (![window isKindOfClass:[UIView class]]) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    if (!window) {
        window = [[UIApplication sharedApplication].windows objectAtIndex:0];
    }
    return window;
}

#pragma mark - height & size

+ (CGFloat)heightOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines {
    return [self heightOfText:text fontSize:fontSize forWidth:width forLineHeight:lineHeight constraintToMaxNumberOfLines:numberOfLines firstLineIndent:0 textAlignment:NSTextAlignmentLeft lineBreakMode:NSLineBreakByWordWrapping];
}

+ (CGFloat)heightOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    CGSize size = [self sizeOfText:text fontSize:fontSize forWidth:width forLineHeight:lineHeight constraintToMaxNumberOfLines:numberOfLines firstLineIndent:indent textAlignment:alignment lineBreakMode:lineBreakMode];
    size.height = ceil(size.height);
    return size.height;
}

+ (CGSize)sizeOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    CGSize size = CGSizeZero;
    if ([text length] > 0) {
        UIFont *font = [UIFont systemFontOfSize:fontSize];
        CGFloat constraintHeight = numberOfLines ? numberOfLines * (lineHeight + 1) : 9999.f;
        CGFloat lineHeightMultiple = lineHeight / font.lineHeight;
        
        if ([self _shouldHandleJailBrokenCase]) {
            NSAttributedString *attrString = [self attributedStringWithString:text fontSize:fontSize lineHeight:lineHeight lineBreakMode:NSLineBreakByWordWrapping isBoldFontStyle:NO firstLineIndent:indent textAlignment:alignment];
            size = [attrString boundingRectWithSize:CGSizeMake(width, constraintHeight) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
        }
        else {
            NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
            style.lineBreakMode = lineBreakMode;
            style.alignment = alignment;
            style.lineHeightMultiple = lineHeightMultiple;
            style.minimumLineHeight = font.lineHeight * lineHeightMultiple;
            style.maximumLineHeight = font.lineHeight * lineHeightMultiple;
            style.firstLineHeadIndent = indent;
            size = [text boundingRectWithSize:CGSizeMake(width, constraintHeight)
                                      options:NSStringDrawingUsesLineFragmentOrigin
                                   attributes:@{NSFontAttributeName:font,
                                                NSParagraphStyleAttributeName:style,
                                                }
                                      context:nil].size;
        }
        
    }
    return size;
}

#pragma mark - attributed string

+ (NSMutableAttributedString *)attributedStringWithString:(NSString *)string fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode
{
    return [self attributedStringWithString:string fontSize:fontSize lineHeight:lineHeight lineBreakMode:lineBreakMode isBoldFontStyle:NO firstLineIndent:0 textAlignment:NSTextAlignmentLeft];
}

+ (NSMutableAttributedString *)attributedStringWithString:(NSString *)string fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode isBoldFontStyle:(BOOL)isBold firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment
{
    if (isEmptyString(string)) {
        return [[NSMutableAttributedString alloc] initWithString:@""];
    }
    
    NSDictionary *attributes = [self _attributesWithFontSize:fontSize lineHeight:lineHeight lineBreakMode:lineBreakMode isBoldFontStyle:isBold firstLineIndent:indent textAlignment:alignment];
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[self parseEmojiInTextKitContext:string fontSize:fontSize]];;

    [attributedString addAttributes:attributes range:NSMakeRange(0, attributedString.length)];
    return attributedString;
}

+ (NSDictionary *)_attributesWithFontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode isBoldFontStyle:(BOOL)isBold firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment
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

+ (BOOL)_shouldHandleJailBrokenCase
{
    static float currentOsVersionNumber = 0;
    static BOOL s_is_jailBroken = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currentOsVersionNumber = [[[UIDevice currentDevice] systemVersion] floatValue];
        NSString *filePath = @"/Applications/Cydia.app";
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            s_is_jailBroken = YES;
        }
        
        filePath = @"/private/var/lib/apt";
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            s_is_jailBroken = YES;
        }

    });
    return currentOsVersionNumber < 9.f && s_is_jailBroken;
}

+ (NSAttributedString *)parseEmojiInTextKitContext:(NSString *)text fontSize:(CGFloat)fontSize
{
    if (isEmptyString(text)) {
        return [[NSAttributedString alloc] initWithString:@""];
    }
    NSAttributedString *string = nil;
    if (string == nil) {
        string = [[NSAttributedString alloc] initWithString:text];
    }
    return string;
}

#pragma mark - url string

+ (NSURL *)URLWithURLString:(NSString *)str
{
    if (str.length == 0) {
        return nil;
    }
    NSString * fixStr = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSURL * u = [NSURL URLWithString:fixStr];
    if (!u) {
        u = [NSURL URLWithString:[fixStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
    return u;
}

@end
