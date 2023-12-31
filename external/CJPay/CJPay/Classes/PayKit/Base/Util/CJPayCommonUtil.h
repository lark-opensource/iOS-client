//
//  CJPayCommonUtil.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN;

extern NSString * const kCJPayContentHeightKey;

@class CJPayAPIBaseResponse;

@interface CJPayCommonUtil : NSObject

/**
 MD5 加密

 @param content 要加密的数据
 @return 加密然后base64的数据
 */
+ (NSString *)createMD5With:(NSString *)content;

/**
 Base64 加密

 @param plainString 要base64的字符串
 @return base64的结果
 */
+ (NSString *)cj_base64:(NSString *)plainString;

/**
 Base64 解密

 @param base64String 要解密的base64内容
 @return 解密结果
 */
+ (NSString *)cj_decodeBase64:(NSString *)base64String;

+ (NSString*)dictionaryToJson:(NSDictionary *)dic;
+ (NSDictionary *)dictionaryFromJsonObject:(id)json;

+ (NSString *)arrayToJson:(NSArray *)array;

+ (nullable NSDictionary *)jsonStringToDictionary:(NSString *)jsonString;

+ (NSString *)dateStringFromTimeStamp:(NSTimeInterval )timeStamp
                           dateFormat:(NSString *)dateFormat;
// 在url后面拼接参数
+ (NSString *)appendParamsToUrl:(NSString *)url params: (NSDictionary *)params;

// 解析scheme
+ (NSDictionary *)parseScheme:(NSString *)schemeString;
// 生成scheme
+ (NSString *)generateScheme:(NSDictionary *)schemeDic;

//传入 秒  得到  xx分钟xx秒
+ (NSString *)getMMSSFromSS:(int)totalTime;

+ (NSString *)getMoneyFormatStringFromDouble:(double)number formatString:(nullable NSString *)formatString;

+ (void)cj_catransactionAction:(void(^)(void))action completion:(void(^)(void))completion;

// 传入schema来打开lynx页面
//+ (void)openLynxPageBySchema:(NSString *)schema completionBlock:(void (^)(CJPayAPIBaseResponse  * _Nullable response))completion;

// 对base64结果进行安全编码
+ (NSString *)replaceNoEncoding:(NSString *)originalStr;

// 对安全base64进行解码
+ (NSString *)replcaeAutoEncoding:(NSString *)encodingStr;

// 对传入的UIView进行截图，并返回UIImage
+ (UIImage *)snapViewToImageView:(UIView *)view;

@end
NS_ASSUME_NONNULL_END;
