//
//  BDUGShareBaseUtil.h
//  AFgzipRequestSerializer
//
//  Created by 杨阳 on 2019/11/3.
//

#ifndef isEmptyString
#define isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#if DEBUG

#define BGUGSHAREASSERT(condition, desc, ...)    \
    do {                \
        if (DEBUG) {\
            if (condition) {        \
                raise(SIGTRAP);\
                NSLog((desc), ##__VA_ARGS__);\
            }\
        }\
    } while(0)

#else
//不是debug环境，啥也不做, 但是要define
#define BGUGSHAREASSERT(condition, desc, ...)

#endif

#import <Foundation/Foundation.h>

@interface BDUGShareBaseUtil : NSObject

+ (NSUInteger)lengthOfWords:(NSString *)string;

+ (UIWindow *)mainWindow;

+ (CGFloat)heightOfText:(NSString *)text fontSize:(CGFloat)fontSize forWidth:(CGFloat)width forLineHeight:(CGFloat)lineHeight constraintToMaxNumberOfLines:(NSInteger)numberOfLines;

+ (NSMutableAttributedString *)attributedStringWithString:(NSString *)string fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode;

+ (NSMutableAttributedString *)attributedStringWithString:(NSString *)string fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight lineBreakMode:(NSLineBreakMode)lineBreakMode isBoldFontStyle:(BOOL)isBold firstLineIndent:(CGFloat)indent textAlignment:(NSTextAlignment)alignment;

+ (NSURL *)URLWithURLString:(NSString *)str;

@end

