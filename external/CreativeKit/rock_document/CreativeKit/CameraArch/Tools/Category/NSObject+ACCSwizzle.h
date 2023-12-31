//
//  NSObject+ACCSwizzle.h
//  Pods
//
//  Created by Hao Yipeng on 2019/12/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ACCSwizzle)

+ (void)acc_swizzleMethodsOfClass:(Class)cls originSelector:(SEL)originSelector targetSelector:(SEL)targetSelector;

@end

NS_ASSUME_NONNULL_END
