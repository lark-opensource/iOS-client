//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <objc/runtime.h>
#import "LynxRootUI.h"
#import "LynxUIOwner+Accessibility.h"
#import "LynxView.h"
#import "UIView+Lynx.h"

@implementation LynxUIOwner (Accessibility)

- (void)addA11yMutation:(NSString *_Nonnull)action
                   sign:(NSNumber *_Nonnull)sign
                 a11yID:(NSString *_Nullable)a11yID
                toArray:(NSMutableArray *)array {
  [array addObject:@{@"target" : sign, @"action" : action, @"a11y-id" : (a11yID ?: @"")}];
}

- (void)addA11yPropsMutation:(NSString *_Nonnull)property
                        sign:(NSNumber *_Nonnull)sign
                      a11yID:(NSString *_Nullable)a11yID
                     toArray:(NSMutableArray *)array {
  if ([self.a11yFilter containsObject:property]) {
    [array addObject:@{
      @"target" : sign,
      @"action" : @"style_update",
      @"a11y-id" : (a11yID ?: @""),
      @"style" : property
    }];
  }
}

- (void)flushMutations:(NSMutableArray *)array withLynxView:(LynxView *)lynxView {
  if (array.count) {
    [lynxView sendGlobalEvent:@"a11y-mutations" withParams:@[ [array copy] ]];
    [array removeAllObjects];
  }
}

- (void)listenAccessibilityFocused {
  if (@available(iOS 9.0, *)) {
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(lynxAccessibilityElementDidBecomeFocused:)
               name:UIAccessibilityElementFocusedNotification
             object:nil];
  }
}

- (void)lynxAccessibilityElementDidBecomeFocused:(NSNotification *)info {
  if (@available(iOS 9.0, *)) {
    if (self.rootUI.context.enableA11yIDMutationObserver) {
      UIView *view = info.userInfo[UIAccessibilityFocusedElementKey];
      if ([view isKindOfClass:UIView.class] && [view isDescendantOfView:self.rootUI.view]) {
        NSInteger sign = view.lynxSign.integerValue;
        LynxUI *ui = [self findUIBySign:sign];
        if (ui) {
          [self.rootUI.view sendGlobalEvent:@"activeElement"
                                 withParams:@[ @{
                                   @"a11y-id" : ui.a11yID ?: @"unknown",
                                   @"element-id" : @(ui.sign) ?: @"unknown"
                                 } ]];
        }
      }
    }
  }
}

- (NSSet<NSString *> *)a11yFilter {
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setA11yFilter:(NSSet<NSString *> *)filter {
  objc_setAssociatedObject(self, @selector(a11yFilter), filter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
