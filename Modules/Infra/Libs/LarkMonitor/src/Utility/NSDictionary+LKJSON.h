//
//  NSDictionary+LKJSON.h
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (LKJSON)

- (BOOL)lk_isValidJSONObject;

- (NSString *)lk_jsonString;

- (NSString * _Nullable)lk_jsonString:(NSError **)error;

- (NSData *)lk_jsonData;

- (NSData *)lk_jsonData:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
