//
//  URLProtocol+Hook.h
//  SKFoundation
//
//  Created by huangzhikai on 2023/3/30.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface URLProtocolHook : NSObject

+ (void)beginHook;
+ (BOOL)doc_swizzleClass:(Class)originClass
                selector:(SEL)originSelector
           swizzledClass:(Class)swizzledClass
        swizzledSelector:(SEL)swizzledSelector;

@end


NS_ASSUME_NONNULL_END
