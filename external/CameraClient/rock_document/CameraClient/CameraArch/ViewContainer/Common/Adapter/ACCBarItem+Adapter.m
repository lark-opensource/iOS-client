//
//  ACCBarItem+Adapter.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/22.
//
#import <objc/runtime.h>
#import "ACCBarItem+Adapter.h"

static const char *ACCbarItemFunctionTypeKey = "ACCbarItemFunctionTypeKey";
static const char *ACCbarItemShowBubbleBlockKey = "ACCbarItemShowBubbleBlockKey";

@implementation ACCBarItem (Adapter)

- (void)setType:(ACCBarItemFunctionType)type
{
    objc_setAssociatedObject(self, ACCbarItemFunctionTypeKey, @(type), OBJC_ASSOCIATION_ASSIGN);
}

- (ACCBarItemFunctionType)type
{
     return [objc_getAssociatedObject(self, ACCbarItemFunctionTypeKey) unsignedIntValue];
}

- (void)setShowBubbleBlock:(dispatch_block_t)showBubbleBlock
{
    objc_setAssociatedObject(self, ACCbarItemShowBubbleBlockKey, showBubbleBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_block_t)showBubbleBlock
{
    return objc_getAssociatedObject(self, ACCbarItemShowBubbleBlockKey);
}

@end
