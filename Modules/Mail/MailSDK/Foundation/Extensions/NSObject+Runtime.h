//
//  NSObject+Runtime.h
//  MailSDK
//
//  Created by tefeng liu on 2021/3/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (Runtime)

+ (BOOL)mail_swizzleClass:(Class)originClass
                selector:(SEL)originSelector
           swizzledClass:(Class)swizzledClass
        swizzledSelector:(SEL)swizzledSelector;
+ (BOOL)mail_swizzleOriginInstanceMethod:(SEL)originalSEL withHookInstanceMethod:(SEL)alternateSEL;
+ (BOOL)mail_swizzleOriginClassMethod:(SEL)originalSEL withHookClassMethod:(SEL)alternateSEL;

/// 通过改变isa指针的方式 交换函数指针
- (BOOL)mail_swizzleInstanceClassIsa:(SEL)originalSEL withHookInstanceMethod:(SEL)alternateSEL;

/// 通过改变isa指针的方式添加protocol。
- (BOOL)mail_isaSwizzleProtocol:(Protocol *)protocol;

- (void)callMethod:(NSString *)method;

@end

NS_ASSUME_NONNULL_END
