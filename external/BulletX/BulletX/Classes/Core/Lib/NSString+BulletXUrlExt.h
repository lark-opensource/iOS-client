//
//  NSString+BulletUrlCode.h
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/11.
//

NS_ASSUME_NONNULL_BEGIN

#ifndef BTD_isEmptyString
#define BTD_isEmptyString(param) (!(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO))
#endif

#ifndef BTD_isEmptyArray
#define BTD_isEmptyArray(param) (!(param) ? YES : ([(param) isKindOfClass:[NSArray class]] ? (param).count == 0 : NO))
#endif

#ifndef BTD_isEmptyDictionary
#define BTD_isEmptyDictionary(param) (!(param) ? YES : ([(param) isKindOfClass:[NSDictionary class]] ? (param).count == 0 : NO))
#endif

@interface NSString (BulletXUrlExt)
- (nonnull NSString *)bullet_urlEncode;
- (nonnull NSString *)bullet_urlDecode;

- (nullable NSString *)bullet_scheme;
- (nullable NSString *)bullet_path;
- (nullable NSString *)bullet_queryString;
- (nullable NSArray<NSString *> *)bullet_pathComponentArray;
- (nullable NSDictionary<NSString *, NSString *> *)bullet_queryDictWithEscapes:(BOOL)escapes;
- (NSString *)bullet_stringByReplacingPercentEscapes;
+ (nullable NSMutableDictionary *)bullet_parseParamsForURL:(NSString *)urlString;
- (NSString *)bullet_stringByAddingQueryDict:(NSDictionary<NSString *, NSString *> *)dict;
- (NSString *)bullet_stringByReplacingScheme:(NSString *)scheme;
- (NSString *)bullet_stringByAddingPercentEscapes;

- (NSString *)bullet_stringByStrippingSandboxPath;
- (NSString *)bullet_stringByAppendingSandboxPath;

@end

NS_ASSUME_NONNULL_END
