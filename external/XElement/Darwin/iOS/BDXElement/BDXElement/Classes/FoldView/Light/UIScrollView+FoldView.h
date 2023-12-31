//  Copyright 2022 The Lynx Authors. All rights reserved.

#import <Lynx/LynxUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (FoldView)
- (void)foldview_addObserverBlockForKeyPath:(NSString *)keyPath block:(void (^)(__weak id obj, id oldVal, id newVal))block;
- (void)foldview_removeObserverBlocksForKeyPath:(NSString *)keyPath;
@end

NS_ASSUME_NONNULL_END
