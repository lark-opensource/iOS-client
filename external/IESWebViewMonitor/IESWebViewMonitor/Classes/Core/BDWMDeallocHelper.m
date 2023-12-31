//
//  BDWMDeallocHelper.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/11/1.
//

#import "BDWMDeallocHelper.h"
#import <objc/runtime.h>

@interface BDWMDeallocHelper ()

@property (nonatomic, copy) BDWMDeallockHelperBlock deallocBlock;
@property (nonatomic, unsafe_unretained) id target;

@end

@implementation BDWMDeallocHelper

+ (void)attachDeallocBlock:(BDWMDeallockHelperBlock)block toTarget:(id)object forKey:(const void*)key {
    if (object) {
        BDWMDeallocHelper *helper = objc_getAssociatedObject(object, key);
        if (!helper) {
            BDWMDeallocHelper *helper = [[BDWMDeallocHelper alloc] init];
            helper.target = object;
            helper.deallocBlock = block;
            objc_setAssociatedObject(object, key, helper, OBJC_ASSOCIATION_RETAIN);
        }
    }
}

+ (void)dettachDeallocBlockInTarget:(id)object forKey:(const void*)key {
    if (object) {
        BDWMDeallocHelper *helper = objc_getAssociatedObject(object, key);
        if (helper) {
            helper.target = nil;
        }
        objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_RETAIN);
    }
}

- (void)dealloc {
    if (_target && _deallocBlock) {
        _deallocBlock();
    }
}

@end
