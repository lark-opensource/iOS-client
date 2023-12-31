//
//  NSURL+BTDAdditions.h
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (BTDAdditions)

@property(nonatomic, assign, class) BOOL btd_fullyEncodeURLParams;

/// 兼容版本的URL构造方式
/// trim空白字符，如果query中有汉字等非法字符会encode在构造
/// @param str urlString
+ (nullable instancetype)btd_URLWithString:(NSString *)str;

+ (nullable instancetype)btd_URLWithString:(NSString *)str relativeToURL:(nullable NSURL *)url;

/// 通过url和query字典来构造url
/// @param URLString urlstring
/// @param queryItems query字典
+ (nullable instancetype)btd_URLWithString:(NSString *)URLString queryItems:(nullable NSDictionary *)queryItems;

+ (nullable instancetype)btd_URLWithString:(NSString *)URLString queryItems:(nullable NSDictionary *)queryItems fragment:(nullable NSString *)fragment;

/*
 Construct a newly created file NSURL from the local file or directory at URLString.
 If the URLString is nil, this function will return nil.
 */
+ (nullable NSURL *)btd_fileURLWithPath:(nullable NSString *)URLString;
/*
 Construct a newly created file NSURL from the local file or directory at path.
 If the URLString is nil, this function will return nil.
 */
+ (nullable NSURL *)btd_fileURLWithPath:(nullable NSString *)path isDirectory:(BOOL)isDir;


- (nullable NSDictionary<NSString *, NSString *> *)btd_queryItems;

- (nullable NSDictionary<NSString *, NSString *> *)btd_queryItemsWithDecoding;

/**
 传入一个query键值对，对当前URL的query进行合并，如果有相同的key，会覆盖掉旧的；没有就新增
 例如：http://example.com/video/search?type=love
 @param key key 例如：release
 @param value value 例如：2019
 @return 合并后新的URL http://example.com/video/search?type=art&release=2019
 */
- (NSURL *)btd_URLByMergingQueryKey:(NSString *)key value:(NSString *)value;

- (NSURL *)btd_URLByMergingQueryKey:(NSString *)key value:(NSString *)value fullyEncoded:(BOOL)fullyEncoded;

/**
 传入一个query字典，对当前URL的query进行合并，如果有相同的key，会覆盖掉旧的；没有就新增
 例如：http://example.com/video/search?type=love
 @param queries 要合并的query字典 例如：{"type":"art","release":"2019"}
 @return 合并后新的URL http://example.com/video/search?type=art&release=2019
 */
- (NSURL *)btd_URLByMergingQueries:(NSDictionary<NSString *,NSString*> *)queries;

- (NSURL *)btd_URLByMergingQueries:(NSDictionary<NSString *,NSString*> *)queries fullyEncoded:(BOOL)fullyEncoded;

@end

NS_ASSUME_NONNULL_END
