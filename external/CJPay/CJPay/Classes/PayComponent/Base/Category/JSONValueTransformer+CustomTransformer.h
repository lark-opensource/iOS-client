//
//  JSONValueTransformer+CustomTransformer.h
//  CJPay
//
//  Created by wangxiaohong on 2019/11/1.
//

#import <JSONModel/JSONValueTransformer.h>

NS_ASSUME_NONNULL_BEGIN

@interface JSONValueTransformer (CustomTransformer)

- (UIColor *)UIColorFromNSString:(NSString *)string;
- (NSString *)JSONObjectFromUIColor:(UIColor *)color;

@end

NS_ASSUME_NONNULL_END
