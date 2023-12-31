//
//  LarkTraitCollectionLoad.m
//  LarkTraitCollection
//
//  Created by 李晨 on 2020/5/25.
//

#import "LarkTraitCollectionLoad.h"
#import <LarkTraitCollection/LarkTraitCollection-Swift.h>
#import <LKLoadable/Loadable.h>

@implementation LarkTraitCollectionLoad
@end

LoadableDidFinishLaunchFuncBegin(hookMethodByTraitCollection)
[RootTraitCollection swizzledIfNeeed];
LoadableDidFinishLaunchFuncEnd(hookMethodByTraitCollection)

