//
//  NSString+DYOpen.h
//  DouyinOpenPlatformSDK
//
//  Created by arvitwu on 2022/9/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (DYOpen)

/// 为 url 添加参数
/// 注意方法内调用系统方法 setQuery 时会自动做 encode，如果外部先 encode 了，则 encodeOutSide 传 YES
/// e.g.  [@"https://open.douyin.com?k1=v1" dyopen_appendQueryString:@"k2=v2"]
/// @param newQueryStr 新的参数字符串
/// @param encodeOutSide 新的 query 是否外部 encode 了。如果外部 encode 了，这个参数传 YES 即可。默认传 NO
/// @return 添加参数后的字符串
- (NSString *)dyopen_appendQueryString:(nonnull NSString *)newQueryStr encodeOutSide:(BOOL)encodeOutSide;
- (NSString *)dyopen_appendQueryString:(nonnull NSString *)newQueryStr;

/// URL encode
- (nonnull NSString *)dyopen_URLEncodedString;

/// URL decode
- (nonnull NSString *)dyopen_URLDecodedString;

/// query 参数转字典
- (nonnull NSDictionary *)dyopen_fromQueryStringToDictionary;

/// 字典转 query 参数
+ (nullable NSString *)dyopen_queryStringFromDictionary:(NSDictionary *_Nonnull)dictionary;

/// 获取 url 参数部分
- (nullable NSString *)dyopen_urlQuery;

/// 获取 url 无参数及锚点部分
- (nullable NSString *)dyopen_urlPath;

/// copy 自 NSString+TTAccountUtils.m 里的 tta_hexMixedString 方法
/// 为了 SDK 不直接依赖 TTAccount，所以 copy 一下方法过来
- (NSString *)dyopen_hexMixedString;

@end

NS_ASSUME_NONNULL_END
