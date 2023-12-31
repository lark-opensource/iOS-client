// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxBackgroundImageLayerInfo.h"
#import "LynxGradient.h"
@implementation LynxBackgroundImageLayerInfo

- (void)drawInContext:(CGContextRef)ctx {
  if ([self.item isKindOfClass:[LynxBackgroundDrawable class]]) {
    BOOL toRestore = NO;
    if (_backgroundClip != LynxBackgroundClipBorderBox ||
        LynxCornerInsetsAreAboveThreshold(_cornerInsets)) {
      CGContextSaveGState(ctx);
      toRestore = YES;
      CGMutablePathRef clipPath = CGPathCreateMutable();
      LynxPathAddRoundedRect(clipPath, _clipRect, _cornerInsets);
      CGContextAddPath(ctx, clipPath);
      CGContextClip(ctx);
      CGPathRelease(clipPath);
    }

    // FIXME: once all background code is merged, this will be removed
    LynxBackgroundDrawable* drawable = (LynxBackgroundDrawable*)self.item;
    drawable.bounds = _clipRect;
    drawable.origin = self.backgroundOrigin;
    drawable.repeatX = self.repeatXType;
    drawable.repeatY = self.repeatYType;
    drawable.posX = self.backgroundPosX;
    drawable.posY = self.backgroundPosY;
    drawable.sizeX = self.backgroundSizeX;
    drawable.sizeY = self.backgroundSizeY;
    drawable.clip = self.backgroundClip;
    [drawable drawInContext:ctx
                 borderRect:_borderRect
                paddingRect:_paddingRect
                contentRect:_contentRect];
    if (toRestore) {
      CGContextRestoreGState(ctx);
    }
    return;
  } else {
    // not loaded
    return;
  }
}
@end
