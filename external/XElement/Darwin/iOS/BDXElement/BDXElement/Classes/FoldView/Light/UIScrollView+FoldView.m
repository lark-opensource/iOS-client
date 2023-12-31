//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "UIScrollView+FoldView.h"
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import "NSObject+BDXPageKVO.h"

@implementation UIScrollView (FoldView)


- (void)foldview_dealloc {
    [self bdx_removeObserverBlocks];
    [self foldview_dealloc];
}

- (void)foldview_addObserverBlockForKeyPath:(NSString *)keyPath block:(void (^)(__weak id obj, id oldVal, id newVal))block {
  [self.class btd_swizzleInstanceMethod:sel_registerName("dealloc") with:@selector(foldview_dealloc)];
  [self bdx_addObserverBlockForKeyPath:keyPath block:block];
}

- (void)foldview_removeObserverBlocksForKeyPath:(NSString *)keyPath {
  [self bdx_removeObserverBlocksForKeyPath:keyPath];
}


@end

