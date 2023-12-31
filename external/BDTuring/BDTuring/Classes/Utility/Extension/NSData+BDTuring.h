//
//  NSData+BDTuring.h
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (BDTuring)

- (nullable NSMutableDictionary *)turing_mutableDictionaryFromJSONData;
- (nullable id)turing_objectFromJSONData;
- (BOOL)turing_isGzipCompressed;

@end

NS_ASSUME_NONNULL_END
