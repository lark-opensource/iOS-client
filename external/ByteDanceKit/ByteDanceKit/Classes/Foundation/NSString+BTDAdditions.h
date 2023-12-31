/**
 * @file NSString+BTDAdditions
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief NSString的扩展
 *
 * @details NSString 一些功能的扩展
 *
 */
//
//  Created by David Alpha Fox on 3/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (BTDAdditions)

@property(nonatomic, assign, class) BOOL btd_fullyEncodeURLParams;

- (NSString *)btd_trimmed;

/**
 
 @return md5字符串
 */
- (nonnull NSString *)btd_md5String;
/**

 @return 返回一个sha1的字符串
 */
- (nonnull NSString *)btd_sha1String;
/**

 @return 返回一个sha256字符串
 */
- (nonnull NSString *)btd_sha256String;
/**
 返回一个UUID字符串
 */
+ (nonnull NSString *)btd_stringWithUUID;
+ (nonnull NSString *)btd_HMACMD5WithKey:(nonnull NSString *)key andData:(nullable NSString *)data;

- (nullable NSString *)btd_hexString;

/**
 返回base64编码后的字符串
 */
- (nullable NSString *)btd_base64EncodedString;

/**
 返回base64解码后的字符串
 */
- (nullable NSString *)btd_base64DecodedString;

/**
 字符串的拆分方法
 @param characterSet 拆分的规则
 @return 返回一个拆分之后的字符串
  Sample Code:
 NSString *str =@"A~B^C";
 NSString *resultStr =[str btd_stringByRemoveAllCharactersInSet:
 [NSCharacterSet characterSetWithCharactersInString:@"^~"]];
 resultStr:ABC
 */
- (nullable NSString *)btd_stringByRemoveAllCharactersInSet:(nonnull NSCharacterSet *)characterSet;
/**

 @return 返回一个去除所有空格的字符串
 */
- (nullable NSString *)btd_stringByRemoveAllWhitespaceAndNewlineCharacters;
/**
 计算文本宽高大小的方法
 */
- (CGFloat)btd_heightWithFont:(nonnull UIFont *)font width:(CGFloat)maxWidth;

- (CGFloat)btd_widthWithFont:(nonnull UIFont *)font height:(CGFloat)maxHeight;

- (CGSize)btd_sizeWithFont:(nonnull UIFont *)font width:(CGFloat)maxWidth;

- (CGSize)btd_sizeWithFont:(nonnull UIFont *)font width:(CGFloat)maxWidth maxLine:(NSInteger)maxLine;
/**
 将\n\n出现两次的换成\n

 @return 返回一个替换之后的字符串
 */
- (nullable NSString *)btd_stringByMergingContinuousNewLine;
/**

 @return 返回一个URLEncode 的字符串
 */
- (nullable NSString *)btd_stringByURLEncode;
/**

 @return 返回一个URLDecode的字符串
 */
- (nullable NSString *)btd_stringByURLDecode;
/**
 判断字符串中是否包含数字

 @return 包含返回YES，否则返回NO
 */
- (BOOL)btd_containsNumberOnly;

/**
 判断字符串是否符合某个正则规则

 @param regex 匹配的规则
 @return 匹配返回YES，否则返回NO
 */
- (BOOL)btd_matchsRegex:(nonnull NSString *)regex;

/**
 匹配正则表达式，匹配到了会执行一个block回调传递一些匹配的信息
 

 @param regex 匹配的规则
 @param options 可选项
 @param block 回调的block
 */
- (void)btd_enumerateRegexMatches:(nonnull NSString *)regex options:(NSRegularExpressionOptions)options usingBlock:(nonnull void (^)(NSString *_Nullable match, NSRange matchRange, BOOL * _Nullable stop))block;
/**
 将字符串转换成一个字典或者数组，如果有错误，返回空
 */
- (nullable id)btd_jsonValueDecoded;
- (nullable id)btd_jsonValueDecoded:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable NSArray *)btd_jsonArray;
- (nullable NSDictionary *)btd_jsonDictionary;

- (nullable NSArray *)btd_jsonArray:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (nullable NSDictionary *)btd_jsonDictionary:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
 将字符串转换成NSNumber

 @return 返回一个NSNumber如果转换成功，出错返回nil
 */
- (nullable NSNumber *)btd_numberValue;
/**
 讲两个字符串拼接成一个url字符串
 
 @param componentString 要拼接的字符串
 @return 返回一个拼接好的url字符串
 Sample Code:
 NSString *str1 = @"http://www.baidu.com";
 NSSting *str2 = @"a=b&c=d"
 NSString *resultStr = [str1 btd_urlStringByAddingComponentString:str2];
 resultStr: http://www.baidu.com?a=b&c=d
 */
- (nullable NSString *)btd_urlStringByAddingComponentString:(nonnull NSString *)componentString;
/**
 讲字符串数组拼接成一个url字符串
 
 @param componentArray 待拼接的字符串数组
 @return 返回一个拼接好的url字符串
 */
- (nullable NSString *)btd_urlStringByAddingComponentArray:(NSArray<NSString *> * _Nonnull)componentArray;
/**
 将字典的参数对拼接成一个url字符串

 @param parameters 参数字典
 @return 返回一个拼接好的url字符串
 */
- (nullable NSString *)btd_urlStringByAddingParameters:(NSDictionary<NSString *, NSString *> * _Nonnull)parameters;

- (nullable NSString *)btd_urlStringByAddingParameters:(NSDictionary<NSString *, NSString *> * _Nonnull)parameters fullyEncoded:(BOOL)fullyEncoded;

/**
 删除指定的参数

 @param parameters 指定的参数字典
 @return 返回删除参数之后的url字符串
 */
- (nullable NSString *)btd_urlStringByRemovingParameters:(NSArray<NSString *> * _Nonnull)parameters;

- (nullable NSString *)btd_urlStringByRemovingParameters:(NSArray<NSString *> * _Nonnull)parameters fullyEncoded:(BOOL)fullyEncoded;

/**

 @return 返回path路径，无path返回空
 */
- (nullable NSArray<NSString *> *)btd_pathComponentArray;
/**
 返回query参数字典。不合规范的参数对会自动过滤。无参数返回nil。

 @return 参数字典
 */
- (nullable NSDictionary<NSString *, NSString *> *)btd_queryParamDict;
/**
 Return a decoded query param dictionary.
 
 @return A NSDictionary.
 */
- (nullable NSDictionary<NSString *, NSString *> *)btd_queryParamDictDecoded;

/**

 @return 返回scheme。空串返回nil。
 */
- (nullable NSString *)btd_scheme;
/**
 
 @return 返回path路径，无path返回空
 */
- (nullable NSString *)btd_path;

/**
 将当前string拼接到Library路径后
 
 @return 拼接后的路径
 */
- (NSString *)btd_prependingLibraryPath;

/**
 将当前string拼接到cache路径后

 @return 拼接后的路径
 */
- (NSString *)btd_prependingCachePath;

/**
 将当前string拼接到Documents路径后
 
 @return 拼接后的路径
 */
- (NSString *)btd_prependingDocumentsPath;

/**
 将当前string拼接到tmp路径后
 
 @return 拼接后的路径
 */
- (NSString *)btd_prependingTemporaryPath;

/**
 Provide safe range for the method -(NSRange)rangeOfString:(NSString *) options:(NSStringCompareOptions)mask range:(NSRange);
 
 @param rangeOfReceiverToSearch The subrange of the receiver to use in the search.
        If the left boundary is out of bounds, an invalid value NSMakeRange(NSNotFound, 0) is returned.
        If the right boundary is out of bounds, the right boundary is changed to the end position of receiver.
 @return The range of the searchString within the receiver string.
 */
- (NSRange)btd_rangeOfString:(NSString *)searchString options:(NSStringCompareOptions)mask range:(NSRange)rangeOfReceiverToSearch;

/**
 Provide safe range for the method -(NSRange)rangeOfString:(NSString *) options:(NSStringCompareOptions)mask range:(NSRange) locale:(nullable NSLocale *);
 @param rangeOfReceiverToSearch The subrange of the receiver to use in the search.
        If the left boundary is out of bounds, an invalid value NSMakeRange(NSNotFound, 0) is returned.
        If the right boundary is out of bounds, the right boundary is changed to the end position of receiver.
 @return The range of the searchString within the receiver string.
 */
- (NSRange)btd_rangeOfString:(NSString *)searchString options:(NSStringCompareOptions)mask range:(NSRange)rangeOfReceiverToSearch locale:(nullable NSLocale *)locale API_AVAILABLE(macos(10.5), ios(2.0), watchos(2.0), tvos(9.0));

@end

@interface NSAttributedString (BTDAdditions)

/**
 @return 返回文本限定宽度时候的高度
 */
- (CGFloat)btd_heightWithWidth:(CGFloat)maxWidth;

@end

NS_ASSUME_NONNULL_END
