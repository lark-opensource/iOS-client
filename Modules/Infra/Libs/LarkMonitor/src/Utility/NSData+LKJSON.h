//
//  NSData+LKJSON.h
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (LKJSON)

- (id)lk_jsonObject;

- (id)lk_jsonMutableObject;

- (id)lk_jsonObject:(NSError **)error;

- (id)lk_jsonMutableObject:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
