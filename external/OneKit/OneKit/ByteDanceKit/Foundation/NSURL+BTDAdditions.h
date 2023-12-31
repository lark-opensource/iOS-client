//
//  NSURL+BTDAdditions.h
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (BTDAdditions)

/// A compatible URL construction method.
/// This method will trim white-space characters, and encode the non-standard characters such as chinese characters.
/// @param URLString The URL string.
+ (nullable instancetype)btd_URLWithString:(NSString *)URLString;

/// A compatible URL construction method.
/// This method will trim white-space characters, and encode the non-standard characters such as chinese characters.
/// @param URLString The URL string.
/// @param baseURL The base URL for the NSURL object.
+ (nullable instancetype)btd_URLWithString:(NSString *)URLString relativeToURL:(nullable NSURL *)baseURL;

/// Construct a URL with URL and query dictionary.
/// @param URLString A URL string.
/// @param queryItems A query dictionary.
+ (nullable instancetype)btd_URLWithString:(NSString *)URLString queryItems:(nullable NSDictionary *)queryItems;

/// Construct a URL with URL and query dictionary.
/// @param URLString A URL string.
/// @param queryItems A query dictionary.
/// @param fragment A URL fragment. For example: #L100
+ (nullable instancetype)btd_URLWithString:(NSString *)URLString queryItems:(nullable NSDictionary *)queryItems fragment:(nullable NSString *)fragment;

- (nullable NSDictionary<NSString *, NSString *> *)btd_queryItems;

- (nullable NSDictionary<NSString *, NSString *> *)btd_queryItemsWithDecoding;

/**
 Use a query key-value pairs merge the URL's querys. If the key exists in the URL's query, the value in the URL will be updated.
 For example: http://example.com/video/search?type=love&region=china
 @param key key For example: release
 @param value value For example: 2019
 @return A new URL after merging. For example: http://example.com/video/search?type=art&region=china&release=2019
 */
- (NSURL *)btd_URLByMergingQueryKey:(NSString *)key value:(NSString *)value;

/**
 Use a query dictionary merge the URL's querys. If the key exists in the URL's query, the value in the URL will be updated.
 For example: http://example.com/video/search?type=love&region=china
 @param queries A query dictionary. For example: {"type":"art","release":"2019"}
 @return A new URL after merging. For example:  http://example.com/video/search?type=art&region=china&release=2019
 */
- (NSURL *)btd_URLByMergingQueries:(NSDictionary<NSString *,NSString*> *)queries;

@end

NS_ASSUME_NONNULL_END
