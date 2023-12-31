//
//  NSString+TTAdSplashAddition.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/8/2.
//  Copyright © 2017年 yin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (TTAdSplashAddition)

/**
 *  获取缓存路径
 *
 *  @return 路径
 */
- (NSString *)ttad_stringCachePath;

/**
 * @brief 返回自身的md5
 * @return 返回自身的md5的16进制字串
 */
- (NSString *)ttad_MD5HashString;

/**
 *  将字符串中的16进制内容转换为对应的bytes
 *  @"6a7bbb8fe2acf6199a76a7630eea74db1ebb8cebec5acd4b2ec59248386aa5ed"
 *  =>
 *  <6a7bbb8f e2acf619 9a76a763 0eea74db 1ebb8ceb ec5acd4b 2ec59248 386aa5ed>
 */
- (NSData *)ttad_bytes;
- (NSString *)ttad_URLEncodedString;
/**
 *  @param separator 分隔符 如 'x' ','
 *  @return 使用分隔符拆分字符串，w=[0], h=[1] w>0,h>0 CGSizeMake(w,h);
 */
- (CGSize)ttad_cgsizeWithSeparator:(NSString *)separator;

+(NSString *)ttad_jsonStringWithObject:(id) object;
+(NSString *)ttad_jsonStringWithString:(NSString *) string;
+(NSString *)ttad_jsonStringWithArray:(NSArray *)array;
+(NSString *)ttad_jsonStringWithDictionary:(NSDictionary *)dictionary;

@end
