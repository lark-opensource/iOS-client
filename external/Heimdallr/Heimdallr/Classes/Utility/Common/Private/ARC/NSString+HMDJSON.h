//
//  NSString+HMDJSON.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (HMDJSON)

- (NSDictionary * _Nullable)hmd_jsonDict;

- (id)hmd_jsonObject;

- (id)hmd_jsonMutableObject;

- (id _Nullable)hmd_jsonObject:(NSError **)error;

- (id _Nullable)hmd_jsonMutableObject:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
