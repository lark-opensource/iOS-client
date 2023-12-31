//
//  LynxView+BDXDeprecated.m
//  BDXLynxKit-Pods-Aweme
//
//  Created by pc on 2021/5/18.
//

#import "LynxView+BDXDeprecated.h"

#import <objc/runtime.h>

@implementation LynxView (BDXDeprecated)

- (void)setBdx_params:(BDXKitParams * _Nonnull)bdx_params
{
    objc_setAssociatedObject(self, @selector(bdx_params), bdx_params, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDXKitParams *)bdx_params
{
    return objc_getAssociatedObject(self, _cmd);
}

@end
