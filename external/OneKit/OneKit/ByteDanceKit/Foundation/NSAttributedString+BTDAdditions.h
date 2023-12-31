//
//  NSAttributedString+BTDAdditions.h
//  ByteDanceKit
//
//  Created by bytedance on 2020/12/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (BTDAdditions)

+ (nullable instancetype)btd_attributedStringWithString:(NSString *)str;
+ (nullable instancetype)btd_attributedStringWithString:(NSString *)str attributes:(nullable NSDictionary<NSAttributedStringKey, id> *)attrs;

@end

NS_ASSUME_NONNULL_END
