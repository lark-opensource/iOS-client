//
//  NSData+HMDJSON.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (HMDJSON)

- (id)hmd_jsonObject;

- (id)hmd_jsonMutableObject;

- (id)hmd_jsonObject:(NSError **)error;

- (id)hmd_jsonMutableObject:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
