// Copyright 2021 The Lynx Authors. All rights reserved.
#import "UIScrollView+Nested.h"

@interface LynxScrollView : UIScrollView

// Force scroll-view to consume gesture and fails specified classes' gesture
@property(nonatomic) BOOL forceCanScroll;
// Use with forceCanScroll. Specify which class should scroll-view fail.
@property(nonatomic) Class blockGestureClass;
// Use with blockGestureClass. Specify a tag for one view in blockGestureClass
@property(nonatomic) NSInteger recognizedViewTag;

@end  // LynxScrollView
