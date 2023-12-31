//
//  NSDictionary+HMDJSON.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (HMDJSON)

- (BOOL)hmd_isValidJSONObject;

- (NSString *)hmd_jsonString;

- (NSString * _Nullable)hmd_jsonString:(NSError **)error;

- (NSData *)hmd_jsonData;

- (NSData *)hmd_jsonData:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
