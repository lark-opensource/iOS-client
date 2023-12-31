//
//  ACCEditPageLayoutManager.m
//  CameraClient
//
//  Created by resober on 2020/3/2.
//

#import "ACCEditPageLayoutManager.h"

#import <CreativeKit/ACCMacros.h>
#import <CoreText/CoreText.h>

typedef void(^ACCEditPageDrawBlock)(CGContextRef graphicsContext);

@interface ACCEditPageLayoutManager ()

@property (nonatomic, copy) ACCEditPageDrawBlock beforeShowGlyhpBlock;
@property (nonatomic, copy) ACCEditPageDrawBlock afterShowGlyphBlock;

@end

@implementation ACCEditPageLayoutManager

- (void)drawUnderlineForGlyphRange:(NSRange)glyphRange
                     underlineType:(NSUnderlineStyle)underlineVal
                    baselineOffset:(CGFloat)baselineOffset
                  lineFragmentRect:(CGRect)lineRect
            lineFragmentGlyphRange:(NSRange)lineGlyphRange
                   containerOrigin:(CGPoint)containerOrigin {
    [super drawUnderlineForGlyphRange:glyphRange
                        underlineType:underlineVal
                       baselineOffset:baselineOffset
                     lineFragmentRect:lineRect
               lineFragmentGlyphRange:lineGlyphRange
                      containerOrigin:containerOrigin];
}

- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin
{
    CGPoint fixOrigin = origin;
    if (self.strokeConfig) {
        self.beforeShowGlyhpBlock = [self p_strokeContextBlockWithWidth:self.strokeConfig.width * 2 color:self.strokeConfig.color join:self.strokeConfig.lineJoin];
        self.afterShowGlyphBlock = [self p_restoreContextBlock];
        [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
        
        fixOrigin.x += 0.1;
        fixOrigin.y -= 0.1;
    }
    self.beforeShowGlyhpBlock = nil;
    self.afterShowGlyphBlock = nil;
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:fixOrigin];
}

- (void)showCGGlyphs:(const CGGlyph *)glyphs positions:(const CGPoint *)positions count:(NSUInteger)glyphCount font:(UIFont *)font matrix:(CGAffineTransform)textMatrix attributes:(NSDictionary<NSAttributedStringKey, id> *)attributes inContext:(CGContextRef)graphicsContext
{
    ACCBLOCK_INVOKE(self.beforeShowGlyhpBlock, graphicsContext);
    [super showCGGlyphs:glyphs positions:positions count:glyphCount font:font matrix:textMatrix attributes:attributes inContext:graphicsContext];
    ACCBLOCK_INVOKE(self.afterShowGlyphBlock, graphicsContext);
}


#pragma mark - Core Graphic
- (ACCEditPageDrawBlock)p_restoreContextBlock
{
    return ^(CGContextRef context) {
        CGContextRestoreGState(context);
    };
}

- (ACCEditPageDrawBlock)p_strokeContextBlockWithWidth:(CGFloat)width color:(UIColor *)color join:(CGLineJoin)join
{
    return ^(CGContextRef context) {
        CGContextSaveGState(context);
        
        CGContextSetTextDrawingMode(context, kCGTextStroke);
        CGContextSetLineWidth(context, width);
        CGContextSetLineJoin(context, join);
        CGContextSetStrokeColorWithColor(context, color.CGColor);
    };
}


@end
