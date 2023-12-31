//
//  NSArray+HMDJSON.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/15.
//

#import "HMDJSONObjectProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (HMDJSON) <HMDJSONObjectProtocol>

- (NSString * _Nullable)hmd_jsonString;

- (NSString * _Nullable)hmd_jsonString:(NSError * _Nullable * _Nullable)error;

- (NSData * _Nullable)hmd_jsonData;

- (NSData * _Nullable)hmd_jsonData:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
