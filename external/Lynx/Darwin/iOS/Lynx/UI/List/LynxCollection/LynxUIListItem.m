//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "LynxUIListItem.h"
#import "LynxComponentRegistry.h"
#import "LynxPropsProcessor.h"
// TODO(hujing.1): separate UIListItem with UIComponent
@implementation LynxUIListItem
#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("list-item")
#else
LYNX_REGISTER_UI("list-item")
#endif

@end
