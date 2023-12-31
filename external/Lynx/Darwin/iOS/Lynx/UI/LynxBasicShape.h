//  Copyright 2023 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LynxBasicShape : NSObject
- (UIBezierPath*)pathWithFrameSize:(CGSize)frameSize;
@end

#ifdef __cplusplus
extern C {
#endif
  LynxBasicShape* LBSCreateBasicShapeFromArray(NSArray * array);
  CGPathRef LBSCreatePathFromBasicShape(LynxBasicShape * shape, CGSize viewport);
#ifdef __cplusplus
}
#endif
NS_ASSUME_NONNULL_END
