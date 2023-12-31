// Copyright 2021 The Lynx Authors. All rights reserved.

#import "BDXLynxTigerVideoView.h"
#import <Lynx/LynxComponentRegistry.h>

@implementation BDXLynxTigerVideoView

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-video-tiger")
#else
LYNX_REGISTER_UI("x-video-tiger")
#endif

@end
