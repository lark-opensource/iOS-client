//
//  BDPMorePanelItem+Private.h
//  Timor
//
//  Created by liuxiangxin on 2019/9/19.
//

#import <Foundation/Foundation.h>
#import "BDPMorePanelItem.h"

FOUNDATION_EXPORT const NSInteger BDPMorePanelItemPriorityOptional;
FOUNDATION_EXPORT const NSInteger BDPMorePanelItemPriorityRequire;

@interface BDPMorePanelItem (Private)

@property (nonatomic, readwrite) NSInteger priority;
@property (nonatomic, readonly) BOOL canHidden;

+ (instancetype _Nonnull )itemWithType:(BDPMorePanelItemType)type
                                  name:(NSString *_Nullable)name
                                  icon:(UIImage *_Nullable)icon
                                action:(BDPMorePanelItemAction _Nullable )action;

@end
