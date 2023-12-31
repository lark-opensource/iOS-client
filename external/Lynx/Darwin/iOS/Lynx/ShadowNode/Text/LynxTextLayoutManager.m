// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxTextLayoutManager.h"
#import "LynxTextStyle.h"

@implementation LynxTextLayoutManager

- (void)showCGGlyphs:(const CGGlyph *)glyphs
           positions:(const CGPoint *)positions
               count:(NSUInteger)glyphCount
                font:(UIFont *)font
              matrix:(CGAffineTransform)textMatrix
          attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
           inContext:(CGContextRef)graphicsContext {
  if ([attributes objectForKey:LynxTextColorGradientKey] != nil &&
      // iOS unicode emoji use System AppleColorEmojiUI font
      // So here can use font name to check if sub glyphs is emoji
      ![font.fontName isEqualToString:@".AppleColorEmojiUI"]) {
    NSMutableDictionary *mutableAttr = [attributes mutableCopy];

    if ([mutableAttr objectForKey:NSShadowAttributeName] != nil) {
      // If text has shadow, need to draw shadow first
      // We use transparent text color to make sure only shadow and background is rendered
      UIColor *color = [attributes objectForKey:NSForegroundColorAttributeName];

      [mutableAttr setObject:[UIColor clearColor] forKey:NSForegroundColorAttributeName];

      [super showCGGlyphs:glyphs
                positions:positions
                    count:glyphCount
                     font:font
                   matrix:textMatrix
               attributes:mutableAttr
                inContext:graphicsContext];

      [mutableAttr removeObjectForKey:NSShadowAttributeName];
      if (color) {
        [mutableAttr setObject:color forKey:NSForegroundColorAttributeName];
      } else {
        [mutableAttr removeObjectForKey:NSForegroundColorAttributeName];
      }
    }
    // part of this text contains gradient
    LynxGradient *gradient = [mutableAttr objectForKey:LynxTextColorGradientKey];
    CGRect rect = [self usedRectForTextContainer:self.textContainers[0]];
    // if positions[0] != rect.origin this means there are offsetX outside NSLayoutManager
    CGSize size = CGSizeMake(MAX(rect.origin.x, positions[0].x) + rect.size.width,
                             rect.origin.y + rect.size.height);

    UIGraphicsBeginImageContextWithOptions(size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef maskContext = UIGraphicsGetCurrentContext();
    CGFontRef fontRef = CGFontCreateWithFontName((CFStringRef)font.fontName);
    CGContextSetFont(maskContext, fontRef);
    CGContextSetTextMatrix(maskContext, textMatrix);
    CGContextTranslateCTM(maskContext, 0, size.height);
    CGContextScaleCTM(maskContext, 1, -1);
    CGContextSetFontSize(maskContext, font.pointSize);
    CGContextSetFillColorWithColor(maskContext, [[UIColor blackColor] CGColor]);
    ///  _________________
    ///  |    | offset y
    ///  | -------------------
    ///  | x  | text content
    ///
    ///  After rendering, the layer position will translate -offset.x and -offset.y.
    ///  The text's origin has changed outside with offset set.
    ///  Move it back to ensure all glyphs rendered correctly on newly created context.
    ///
    ///  Then we got a text mask without offset
    ///
    ///   ________________
    ///  | text content
    ///  |________________
    ///
    CGContextTranslateCTM(maskContext, -_overflowOffset.x, -_overflowOffset.y);
    [super showCGGlyphs:glyphs
              positions:positions
                  count:glyphCount
                   font:font
                 matrix:textMatrix
             attributes:mutableAttr
              inContext:maskContext];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGFontRelease(fontRef);
    // clip a mask for this
    CGContextSaveGState(graphicsContext);
    // restore the position offset.
    CGContextTranslateCTM(graphicsContext, _overflowOffset.x, _overflowOffset.y);
    CGContextClipToMask(graphicsContext, CGRectMake(0, 0, size.width, size.height),
                        [image CGImage]);
    [gradient draw:graphicsContext withRect:CGRectMake(0, 0, size.width, size.height)];
    CGContextRestoreGState(graphicsContext);
  } else {
    [super showCGGlyphs:glyphs
              positions:positions
                  count:glyphCount
                   font:font
                 matrix:textMatrix
             attributes:attributes
              inContext:graphicsContext];
  }
}

@end
