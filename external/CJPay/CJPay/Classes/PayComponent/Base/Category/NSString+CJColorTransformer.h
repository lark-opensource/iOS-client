//
//  NSString+CJColorTransformer.h
//  CJComponents
//
//  Created by liyu on 2019/11/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (CJColorTransformer)

- (UIColor *)cj_colorWithDefaultColor:(UIColor * _Nullable)defaultColor;

@end

NS_ASSUME_NONNULL_END
