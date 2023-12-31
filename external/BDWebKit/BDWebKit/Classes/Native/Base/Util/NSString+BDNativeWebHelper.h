//
//  NSString+BDNativeWebHelper.h
//  BDNativeWebView
//
//  Created by liuyunxuan on 2019/7/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (BDNativeHelper)

- (NSArray *)bdNativeJSONArray;

- (NSDictionary *)bdNativeJSONDictionary;

- (NSMutableDictionary *)bdNativeMutableJSONDictionary;

- (id)bdNativeJSONObject;

- (NSArray <NSString *>*)bdNative_nativeDivisionKeywords;
@end

NS_ASSUME_NONNULL_END
