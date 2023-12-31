//
//  NSString+BDPExtension.h
//  Timor
//
//  Created by 涂耀辉 on 2018/6/20.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface NSString (BDPExtension)

// size计算
- (CGSize)tma_sizeForFont:(UIFont *)font size:(CGSize)size mode:(NSLineBreakMode)lineBreakMode;
- (CGFloat)tma_widthForFont:(UIFont *)font;
- (CGFloat)tma_heightForFont:(UIFont *)font width:(CGFloat)width;

// URL Encoding
- (NSString *)URLEncodedString;
- (NSString *)URLDecodedString;
+ (NSString *)URLEncodedStringPath:(NSString *)path query:(NSDictionary *)query;

- (NSString *)bdp_md5;

// sub string
- (NSString *)bdp_subStringForMaxWordLength:(NSUInteger)wordLength withBreak:(BOOL)shouldBreak;

- (NSString *)bdp_md5String;

// attribute string utils
+ (NSMutableAttributedString *)bdp_attributedStringWithString:(NSString *)string
                                                     fontSize:(CGFloat)fontSize
                                                   lineHeight:(CGFloat)lineHeight
                                                lineBreakMode:(NSLineBreakMode)lineBreakMode
                                              isBoldFontStyle:(BOOL)isBold
                                              firstLineIndent:(CGFloat)indent
                                                textAlignment:(NSTextAlignment)alignment;

- (NSMutableAttributedString *)bdp_attributedStringWithFontSize:(CGFloat)fontSize
                                                     lineHeight:(CGFloat)lineHeight
                                                  lineBreakMode:(NSLineBreakMode)lineBreakMode
                                                isBoldFontStyle:(BOOL)isBold
                                                firstLineIndent:(CGFloat)indent
                                                  textAlignment:(NSTextAlignment)alignment;

/**
 获取路径中的文件名
 
 比如"/usr/cache/xxx.jpn.pkg.js"则得到"xxx"
 */
- (NSString *)bdp_fileName;

/** 如果字符串路径中有参数, 则会删除?及?以后的所有内容 */
- (NSString *)bdp_urlWithoutParmas;

/** 如果字符串中有scheme，则返回其中的scheme，否则是nil */
- (NSString *)bdp_urlScheme;

/** 末尾补充'/' */
- (NSString *)bdp_fileUrlAddDirectoryPathIfNeeded;

/** 末尾删除'/' */
- (NSString *)bdp_fileUrlDeleteDirectoryPath;

- (NSString *)bdp_urlWithoutScheme;

+ (NSString *)bdp_stringFromBase64String:(NSString *)base64String;

/**
 整形判断
 */
+ (BOOL)bdp_isPureInt:(NSString* _Nonnull)string;

/// 判断一段字符串长度(汉字2字节)
+ (NSUInteger)bdp_textLength:(NSString *_Nullable)text;

- (NSData *)hexStringToData;

/// 做URL日志打印的安全截断
+ (nullable NSString *)safeURLString:(NSString  * _Nullable)url;
+ (nullable NSString *)safeURL:(NSURL * _Nullable)URL;
- (nullable NSString *)safeURLString;
/// URL日志打印的AES256加密
+ (nullable NSString *)safeAES256URLString:(NSString * _Nullable)url key:(NSString *)key iv:(NSString *)iv;
+ (nullable NSString *)safeAES256URL:(NSURL * _Nullable)url key:(NSString *)key iv:(NSString *)iv;
- (nullable NSString *)safeAES256Key:(NSString *)key iv:(NSString *)iv;

@end
