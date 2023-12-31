//
//  NaviPreload.m
//  LarkNavigation
//
//  Created by Lark iOS on 2021/6/8.
//

#import "NaviPreload.h"
#import <LarkNavigation/LarkNavigation-swift.h>

@implementation NaviPreload

+ (void)load {
    Class i18nClass = NSClassFromString(@"I18nManagerPreload");
    if (i18nClass && [i18nClass respondsToSelector:@selector(preload)]) {
        [i18nClass performSelector:@selector(preload)];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [LKNaviPreload preload];
    });
}

@end
