//
//  DouyinOpenSDKUtils.h
//
//  Created by ByteDance on 18/9/2017.
//  Copyright (c) 2018年 ByteDance. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (DYOpenCast)
+ (Class _Nonnull)DYOpen_class;
+ (nullable instancetype)DYOpen_cast:(id _Nullable)any
                    warnOnFailure:(BOOL)warnOnFailure;
@end

#define DouyinOpenPlatform_isEmptyString(str)        (![str isKindOfClass:[NSString class]] || [str length] == 0)

#define DouyinOpenPlatform_CHECK_MainThread()    NSCAssert([NSThread isMainThread], @"Must run in main thread")

#define DouyinOpenPlatform_AS(__obj__,__clazz__) ([__obj__ isKindOfClass:[__clazz__ class]]?(__clazz__ *)__obj__:nil)

#define DouyinOpenPlatformLocalizedString(key, comment)\
({\
    DouyinLocalizedString(key, comment);\
})

#define DynamicCast(x, c) ((c *)([x isKindOfClass:[c class]] ? x : nil))

FOUNDATION_EXTERN NSString * _Nonnull DouyinLocalizedString(NSString * _Nonnull str, NSString * _Nullable comment);

FOUNDATION_EXTERN NSString * _Nullable DouyinDevicePlatform(void);

#ifndef btd_keywordify
#if DEBUG
  #define btd_keywordify autoreleasepool {}
#else
  #define btd_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) btd_keywordify __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) btd_keywordify __block __typeof__(object) block##_##object = object;
    #endif
#endif

#define BLOCK_EXEC(block, ...)\
if (block) {\
    block(__VA_ARGS__);\
};

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object) btd_keywordify __typeof__(object) object = weak##_##object;
    #else
        #define strongify(object) btd_keywordify __typeof__(object) object = block##_##object;
    #endif
#endif

#define UIColorFromRGBA(__rgb__, __alpha__) \
[UIColor colorWithRed:((float)(((__rgb__) & 0xFF0000) >> 16))/255.0 \
green:((float)(((__rgb__) & 0xFF00) >> 8))/255.0 \
blue:((float)((__rgb__) & 0xFF))/255.0 \
alpha:(__alpha__)]

#define DYOpenBlock_Invoke(block, ...) (block ? block(__VA_ARGS__) : 0)

#pragma mark - UI
#define DYOPEN_SCREEN_WIDTH  CGRectGetWidth([[UIScreen mainScreen] bounds])
#define DYOPEN_SCREEN_HEIGHT CGRectGetHeight([[UIScreen mainScreen] bounds])

#pragma mark - Cast
/*-----------------------------------------------*/
//             Cast - 类型判断与转换
/*-----------------------------------------------*/
#define DYOpen_SHORT_CALL_STACK(len) (DYOpenArraySlice([NSThread callStackSymbols], 0, (len)))

#define DYOpen_AS(clz, value) ([clz DYOpen_cast:(value) warnOnFailure:YES])
#define DYOpen_AS_VAR(var, clz, value) clz *var = DYOpen_AS(clz, value)

#define DYOpen_CLASS_NAME(clz) (NSStringFromClass([clz DYOpen_class]))

#define DYOpen_IS(clz, object) ([object isKindOfClass:[clz DYOpen_class]])
#define DYOpen_IS_NOT(clz, object) (![object isKindOfClass:[clz DYOpen_class]])

#define DYOpen_IS_PROTOCOL(proto, object) ([object conformsToProtocol:@protocol(proto)])
#define DYOpen_AS_PROTOCOL(proto, object) ((NSObject<proto> *)(DYOpenCastProtocol(@protocol(proto), (object), YES)))

#define DYOpen_let __auto_type const
#define DYOpen_var __auto_type
#define UNUSED_VAR(x) (void)(x)

#if __LP64__ || 0 || NS_BUILD_32_LIKE_64
#define DYOpen_ARM64 1
#else
#define DYOpen_ARM64 0
#endif

#define DYOpen_STR(...) ([NSString stringWithFormat:__VA_ARGS__])

#define DYOpen_DECLARE_KVO_CONTEXT(name) static void *name = &#name;
#define DYOpen_DECLARE_EXTERN_CONST_NSSTRING(name) extern NSString *const name;
#define DYOpen_DECLARE_CONST_NSSTRING(name) NSString *const name = @"" #name;
#define DYOpen_DECLARE_STATIC_CONST_NSSTRING(name) static NSString *const name = @"" #name;

#define DYOpen_EQ(a, b) DYOpenEqual((a), (b))

#define SECOND 1.0f
#define MINUTE (SECOND * 60.0f)
#define HOUR (MINUTE * 60.0f)
#define DAY (HOUR * 24.0f)
#define WEEK (DAY * 7.0f)
#define MONTH (DAY * 31.0f)
#define YEAR (DAY * 365.24f)

// 常量
FOUNDATION_EXTERN NSString *_Nonnull const DYOpenULDomain;
FOUNDATION_EXTERN NSString *_Nonnull const DYOpenLiteULDomain;

// 方法
FOUNDATION_EXTERN NSArray * _Nullable DYOpenSafeArray(NSArray * _Nullable array);
FOUNDATION_EXTERN NSNumber * _Nullable DYOpenSafeNumber(NSNumber * _Nullable number);
FOUNDATION_EXTERN NSString * _Nullable DYOpenSafeString(NSString * _Nullable string);
FOUNDATION_EXTERN NSDictionary * _Nullable DYOpenSafeDictionary(NSDictionary * _Nullable dict);
FOUNDATION_EXTERN BOOL DYOpenIsEmptyString(NSString * _Nullable string);

// run on main thread (sync)
static inline void DYOPEN_RUN_ON_MAIN_THREAD_SYNC(dispatch_block_t _Nonnull block) {
    if ([NSThread isMainThread]) {
        !block ?: block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

// run on main thread (async)
static inline void DYOPEN_RUN_ON_MAIN_THREAD_ASYNC(dispatch_block_t _Nonnull block) {
    if ([NSThread isMainThread]) {
        !block ?: block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}


@interface DouyinOpenSDKUtils : NSObject

/// 将 QueryItems 添加到 baseURLString 中，并生成新的 NSURL 对象
+ (nullable NSString *)dyopen_urlWithBaseURLString:(NSString * _Nonnull)originalURLString
                                byAppendQueryItems:(NSDictionary * _Nullable)items;

/// 从 url 中解析查询字符串
+ (nullable NSDictionary *)dyopen_queryDictionaryFromURLString:(NSString * _Nonnull)urlString;

/// 添加通用参数（body）
+ (nonnull NSMutableDictionary *)appendCommonParamsDictFor:(nullable NSDictionary *)originDict;

/// 添加通用参数（query）
+ (nonnull NSString *)appendCommonParamsStringFor:(nullable NSString *)originString;

/// 通用参数
+ (nonnull NSDictionary *)commonParams;

// 是否是内部版本
+ (BOOL)isInternal;

// 是否安装抖音
+ (BOOL)hasInstallDouyin;

@end

@interface NSURL (DYOpenPlatform_URLUtils)

/**
 获取NSURL中查询参数
 
 @return 查询参数
 */
- (nullable NSDictionary *)douyin_queryDictionary;

- (nullable NSURL *)douyin_universalLink;

- (nullable NSURL *)douyinLite_universalLink;

@end

@interface NSString (DYOpenPlatform_StringUtils)
/**
 * @brief 返回BundleID的md5
 *
 * @return 返回BundleID的md5
 */
+ (nonnull NSString *)dyopen_md5ForAppId;
/**
 追加items项至NSString后作为NSURL查询参数部分
 
 @param items 查询参数
 @return 返回string+items所生成的新NSURL对象
 */
- (nullable NSURL *)douyin_URLByAppendQueryItems:(NSDictionary * _Nullable)items;

- (nullable NSString *)dyopen_md5String;

/**
 获取字符串对应NSURL中查询参数
 
 @return 查询参数
 */
- (nullable NSDictionary *)douyin_queryDictionary;

+ (nonnull NSString *)douyin_timeStamp;

+ (nonnull NSString *)douyin_accurateTimestamp;

@end

@interface NSString (DYOpenPlatform_URLEnDecoder)

/** 将字符串进行URL编码 */
- (nullable NSString *)douyin_URLEncodedString;

/** 将字符串进行URL解密 */
- (nullable NSString *)douyin_URLDecodedString;

/** 将字符串反序列化为JSON对象（字典、数组等） */
- (nullable id)douyin_deserializeJSONObject;

@end

@interface NSArray (DYOpenPlatform_ToSerializatedString)

/**
 将数组转化为UTF8编码的字符串
 
 @return 编码字符串
 */
- (nonnull NSString *)douyin_serializatedString;

@end

@interface NSOrderedSet (DYOpenPlatform_PermissionToString)

/**
 将必选权限集合转化为字符串
 
 @return 编码字符串
 */
- (nonnull NSString *)douyin_permissionString;

/**
 将附加可选权限集合转化为字符串
 PS: 会拼接选中类型
 
 @return 编码字符串
 */
- (nonnull NSString *)douyin_additionPermissionString;

/// 将附加可选权限集合转化为字符串
/// @param onlyScope 仅拼接 scope，不拼接选中类型
- (NSString *_Nullable)douyin_additionPermissionStringOnlyScope:(BOOL)onlyScope;

@end

@interface NSDictionary (DYOpenPlatform_ToSerializatedString)

/**
 将字典转化为UTF8编码的字符串
 
 @return 编码字符串
 */
- (nonnull NSString *)douyin_serializatedString;

@end

@interface NSBundle (DYOpenPlatform_Bundle)

+ (NSBundle *_Nullable)douyin_bundle;

+ (NSString *_Nullable)douyin_mainBundleID;
@end

@interface NSLocale (DYOpenPlatform_LangCode)

/**
 获取系统设置且SDK支持语言，如果系统设置的语言，SDK 不支持，则返回en
 
 @return 语言所对应的编号
 */
- (nonnull NSString *)douyin_supportLangIdentifier;

/**
 判断当前语言是否属于LTR语系
 
 @return 返回当前语言是是否为LTR
 */
- (BOOL)douyin_isLTR;

@end

