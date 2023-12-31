//
//  ACCDeallocHelper.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/23.
//

#import "ACCDeallocHelper.h"
#import <objc/runtime.h>

@interface ACCDeallocHelper ()

@property (copy, nonatomic) ACCDeallocHelperBlock callback;
@property (unsafe_unretained, nonatomic) id target;

@end

@implementation ACCDeallocHelper

+ (void)attachToObject:(nonnull id)object key:(const void*)key whenDeallocDoThis:(ACCDeallocHelperBlock)aThis
{
    if (object) {
        ACCDeallocHelper *tmpHelper = objc_getAssociatedObject(object, key);
        if (!tmpHelper) {
            ACCDeallocHelper *helper = [[ACCDeallocHelper alloc] init];
            helper.target = object;
            helper.callback = aThis;
            objc_setAssociatedObject(object, key, helper, OBJC_ASSOCIATION_RETAIN);
        }
    }
}

+ (void)dettachObject:(nonnull id)object key:(const void*)key
{
    if (object) {
        ACCDeallocHelper *tmpHelper = objc_getAssociatedObject(object, key);
        if (tmpHelper) {
            tmpHelper.target = nil;
        }
        objc_setAssociatedObject(object, key, nil, OBJC_ASSOCIATION_RETAIN);
    }
}

- (void)dealloc
{
    if (_target && _callback) {
        _callback();
    }
}

@end

