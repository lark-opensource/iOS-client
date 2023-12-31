//
//  SGMMethodSwizzle.h
//  SecGuard
//
//  Created by jianghaowne on 2018/5/6.
//

#import <Foundation/Foundation.h>

@interface SGMMethodSwizzle : NSObject

+ (void)swizzleWithClass:(Class)class selector:(SEL)selector block:(id)block;
+ (void)unswizzleWithClass:(Class)class selector:(SEL)selector;
+ (SEL)swizzledSELWithClass:(Class)class selector:(SEL)selector;

@end
