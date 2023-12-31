//
//  NSNumber+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/3/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSNumber (BTDAdditions)

/**
 用字符串生成一个NSNumber

 @param string 用于生成NSNumber的字符串，例如 @"12", @"12.345", @" -0xFF", @" .23e99 "
 @return 返回一个NSNumber，如果出错返回空
 */
+ (nullable NSNumber *)btd_numberWithString:(nonnull NSString *)string;

@end

NS_ASSUME_NONNULL_END
