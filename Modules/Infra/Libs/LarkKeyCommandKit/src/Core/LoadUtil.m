//
//  LoadUtil.m
//  LarkKeyCommandKit
//
//  Created by 李晨 on 2020/2/6.
//

#import <Foundation/Foundation.h>
#import <LarkKeyCommandKit/LarkKeyCommandKit-Swift.h>
#import "LoadUtil.h"
#import <LKLoadable/Loadable.h>

@implementation LarkKeyCommandKitLoad
@end

LoadableRunloopIdleFuncBegin(hookMethodByKeyCommandKit)
[KeyCommandKit swizzledIfNeeded];
if (@available(iOS 13.4, *)) {
    [KeyPressKit swizzledIfNeeded];
}
LoadableRunloopIdleFuncEnd(hookMethodByKeyCommandKit)
