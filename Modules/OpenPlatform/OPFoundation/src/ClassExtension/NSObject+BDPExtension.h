//
//  NSObject+BDPExtension.m
//  Timor
//
//  Created by CsoWhy on 2019/1/10.
//

#import <Foundation/Foundation.h>

@interface NSObject (BDPSwizzle)

+ (BOOL)bdp_swizzleClass:(Class)originClass
                selector:(SEL)originSelector
           swizzledClass:(Class)swizzledClass
        swizzledSelector:(SEL)swizzledSelector;
+ (BOOL)bdp_swizzleOriginInstanceMethod:(SEL)originalSEL withHookInstanceMethod:(SEL)alternateSEL;
+ (BOOL)bdp_swizzleOriginClassMethod:(SEL)originalSEL withHookClassMethod:(SEL)alternateSEL;

/// 通过改变isa指针的方式 交换函数指针
- (BOOL)bdp_isaSwizzleInstance:(SEL)originalSEL withHookInstnceMethod:(SEL)alternateSEL;

/// 通过改变isa指针的方式添加protocol。
- (BOOL)bdp_isaSwizzleProtocol:(Protocol *)protocol;

@end
