//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "LynxUIOwner.h"
@class LynxView;
NS_ASSUME_NONNULL_BEGIN

@interface LynxUIOwner (Accessibility)

- (void)addA11yMutation:(NSString *_Nonnull)action
                   sign:(NSNumber *_Nonnull)sign
                 a11yID:(NSString *_Nullable)a11yID
                toArray:(NSMutableArray *)array;

- (void)addA11yPropsMutation:(NSString *_Nonnull)property
                        sign:(NSNumber *_Nonnull)sign
                      a11yID:(NSString *_Nullable)a11yID
                     toArray:(NSMutableArray *)array;

- (void)flushMutations:(NSMutableArray *)array withLynxView:(LynxView *)lynxView;

- (void)listenAccessibilityFocused;

- (void)setA11yFilter:(NSSet<NSString *> *)filter;
@end

NS_ASSUME_NONNULL_END
