//
//  NSObject+RuntimeExtension.h
//  LarkWebViewContainer
//
//  Created by tefeng liu on 2020/9/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (RuntimeExtension)

+ (BOOL)lkw_swizzleClass:(Class)originClass
                selector:(SEL)originSelector
           swizzledClass:(Class)swizzledClass
        swizzledSelector:(SEL)swizzledSelector;
+ (BOOL)lkw_swizzleOriginInstanceMethod:(SEL)originalSEL withHookInstanceMethod:(SEL)alternateSEL;
+ (BOOL)lkw_swizzleOriginClassMethod:(SEL)originalSEL withHookClassMethod:(SEL)alternateSEL;

/// 通过改变isa指针的方式 交换函数指针
- (BOOL)lkw_swizzleInstanceClassIsa:(SEL)originalSEL withHookInstanceMethod:(SEL)alternateSEL;

/// 通过改变isa指针的方式添加protocol。
- (BOOL)lkw_isaSwizzleProtocol:(Protocol *)protocol;

@end

NS_ASSUME_NONNULL_END
