//
//  BDNativeWebHookUtil.h
//  BDNativeWebComponent
//
//  Created by liuyunxuan on 2019/8/20.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface BDNativeWebHookUtil : NSObject

+ (BOOL)swizzleClass:(Class)class
            oriMethod:(SEL)origSel_
            altMethod:(SEL)altSel_;

@end
