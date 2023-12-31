//
//  BDPMorePanelItem+Private.m
//  Timor
//
//  Created by liuxiangxin on 2019/9/19.
//

#import "BDPMorePanelItem+Private.h"
#import <objc/runtime.h>

@implementation BDPMorePanelItem (Private)

+ (instancetype)itemWithType:(BDPMorePanelItemType)type
                        name:(NSString *_Nullable)name
                        icon:(UIImage *_Nullable)icon
                      action:(BDPMorePanelItemAction _Nullable )action
{
    BDPMorePanelItem *item = [[self alloc] initWithType:type
                                                   name:name
                                                   icon:icon
                                                iconURL:nil
                                                 action:action];
    return item;
}

- (BOOL)canHidden
{
    return self.priority < BDPMorePanelItemPriorityRequire;
}

- (NSInteger)priority
{
    NSNumber *wrapper =  objc_getAssociatedObject(self, @selector(priority));
    
    return wrapper.integerValue;
}

- (void)setPriority:(NSInteger)priority
{
    objc_setAssociatedObject(self, @selector(priority), @(priority), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
