//
//  ByteViewLoadTask.m
//  ByteViewMod
//
//  Created by kiri on 2022/1/6.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

#import "ByteViewLoadTask.h"
#import <LKLoadable/Loadable.h>

@implementation ByteViewLoadTask

@end

LoadableDidFinishLaunchFuncBegin(loadByteView1)
[NSClassFromString(@"LarkByteViewPreloader") performSelector:@selector(didFinishLaunch)];
LoadableDidFinishLaunchFuncEnd(loadByteView1)

LoadableRunloopIdleFuncBegin(loadByteView2)
[NSClassFromString(@"LarkByteViewPreloader") performSelector:@selector(afterFirstRender)];
LoadableRunloopIdleFuncEnd(loadByteView2)
