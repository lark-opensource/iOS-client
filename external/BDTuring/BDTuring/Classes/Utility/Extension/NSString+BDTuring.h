//
//  NSString+BDTuring.h
//  BDTuring
//
//  Created by bob on 2020/3/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (BDTuring)

- (nullable NSDictionary *)turing_dictionaryFromJSONString;
- (nullable NSDictionary *)turing_dictionaryFromBase64String;

@end

NS_ASSUME_NONNULL_END
