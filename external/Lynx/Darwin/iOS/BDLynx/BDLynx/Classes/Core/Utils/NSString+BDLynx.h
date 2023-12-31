//
//  NSString+BDLynx.h
//  BDLynx-Pods-Aweme
//
//  Created by bill on 2020/5/15.
//

#import <Foundation/Foundation.h>

#ifndef BTD_isEmptyString
#define BTD_isEmptyString(param) \
  (!(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO))
#endif

#ifndef BTD_isEmptyArray
#define BTD_isEmptyArray(param) \
  (!(param) ? YES : ([(param) isKindOfClass:[NSArray class]] ? (param).count == 0 : NO))
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NSString (BDLynx)

/**
 * @brief 返回query参数字典。不合规范的参数对会自动过滤。无参数返回nil。
 *
 * @param escapes 是否对参数做解码
 */
- (NSDictionary<NSString *, NSString *> *)BDLynx_queryDictWithEscapes:(BOOL)escapes;

@end

NS_ASSUME_NONNULL_END
