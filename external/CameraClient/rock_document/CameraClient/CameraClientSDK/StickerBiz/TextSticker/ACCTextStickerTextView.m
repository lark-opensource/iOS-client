//
//  ACCTextStickerTextView.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/17.
//

#import "ACCTextStickerTextView.h"

@interface ACCTextStickerTextView ()

@property (nonatomic, strong) NSMutableArray *layerPool;
@property (nonatomic, strong) NSMutableArray <CALayer *> *currentShowLayerArray;

@end

static CGFloat const kACCTextStickerBGColorLeftMargin = 12;
static CGFloat const kACCTextStickerBGColorTopMargin = 6;
static CGFloat const kACCTextStickerBGColorRadius = 6;
static CGFloat const kACCTextStickeTextViewContainerInset = 14;

@implementation ACCTextStickerTextView
@synthesize acc_layoutManager = _acc_layoutManager;
@synthesize acc_textStorage = _acc_textStorage;

- (NSMutableArray *)currentShowLayerArray
{
    if (!_currentShowLayerArray) {
        _currentShowLayerArray = [@[] mutableCopy];
    }
    return _currentShowLayerArray;
}

- (NSMutableArray *)layerPool
{
    if (!_layerPool) {
        _layerPool = [NSMutableArray array];
        [_layerPool addObject:[CAShapeLayer layer]];
    }
    return _layerPool;
}

- (void)drawBackgroundWithFillColor:(UIColor *)fillColor
{
    NSMutableArray *lineRangeArray = [@[] mutableCopy];
    NSMutableArray<NSValue *> *lineRectArray = [@[] mutableCopy];
    
    NSRange range = NSMakeRange(0, 0);
    CGRect lineRect = [self.layoutManager lineFragmentUsedRectForGlyphAtIndex:0 effectiveRange:&range];
    
    if (range.length != 0) {
        [lineRangeArray addObject:[NSValue valueWithRange:range]];
        [lineRectArray addObject:[NSValue valueWithCGRect:lineRect]];
    }
    while (range.location + range.length < self.text.length) {
        lineRect = [self.layoutManager lineFragmentUsedRectForGlyphAtIndex:(range.location + range.length) effectiveRange:&range];
        if (range.length != 0) {
            [lineRangeArray addObject:[NSValue valueWithRange:range]];
            [lineRectArray addObject:[NSValue valueWithCGRect:lineRect]];
        }
    }

    NSMutableArray<NSMutableArray *> *segArray = [@[] mutableCopy];
    NSMutableArray *currentArray = [@[] mutableCopy];
    [segArray addObject:currentArray];
    int i = 0;
    while (i < lineRectArray.count) {
        if (lineRectArray[i].CGRectValue.size.width <= 0.00001) {
            if (currentArray.count != 0) {
                currentArray = [@[] mutableCopy];
                [segArray addObject:currentArray];
            }
        } else {
            [currentArray addObject:lineRectArray[i]];
        }
        i++;
    }
    
    for (CAShapeLayer *layer in self.currentShowLayerArray) {
        [layer removeFromSuperlayer];
        [self.layerPool addObject:layer];
    }
    
    [self.currentShowLayerArray removeAllObjects];
    
    for (NSArray *lineRectArray in segArray) {
        if (lineRectArray.count) {
            [self drawWithLineRectArray:lineRectArray fillColor:fillColor];
        }
    }
}

- (void)drawWithLineRectArray:(NSArray<NSValue *> *)array fillColor:(UIColor *)fillColor
{
    NSMutableArray<NSValue *> *lineRectArray = [array mutableCopy];
    
    CAShapeLayer *leftLayer = nil;
    
    if (self.layerPool.count) {
        leftLayer = self.layerPool.lastObject;
        [self.layerPool removeLastObject];
    } else {
        leftLayer = [CAShapeLayer layer];
    }
    
    leftLayer.fillColor = fillColor.CGColor;
    [self.layer insertSublayer:leftLayer atIndex:0];
    
    [self.currentShowLayerArray addObject:leftLayer];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    if (lineRectArray.count == 1) {
        CGRect currentLineRect = lineRectArray[0].CGRectValue;
        CGPoint topMidPoint = [self topMidPointWithRect:currentLineRect];
        [path moveToPoint:topMidPoint];
        
        CGPoint leftTop = [self leftTopWithRect_up:currentLineRect];
        CGPoint leftTopCenter = CGPointMake(leftTop.x + kACCTextStickerBGColorRadius , leftTop.y + kACCTextStickerBGColorRadius);
        [path addLineToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
        [path addArcWithCenter:leftTopCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI * 1.5 endAngle:M_PI clockwise:NO];
        
        CGPoint leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
        CGPoint leftBottomCenter = CGPointMake(leftBottomPoint.x + kACCTextStickerBGColorRadius, leftBottomPoint.y - kACCTextStickerBGColorRadius);
        [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
        [path addArcWithCenter:leftBottomCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
        
        CGPoint bottomMid = [self bottomMidPointWithRect:currentLineRect];
        [path addLineToPoint:bottomMid];
    } else if (lineRectArray.count > 1) {
        int i = 0;
        while (i < lineRectArray.count - 1) {
            CGRect currentLineRect = lineRectArray[i].CGRectValue;
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            if (fabs(currentLineRect.size.width - nextLineRect.size.width) <= (4 * kACCTextStickerBGColorRadius + 1)) {
                // If the diff between two lines less than 2 * kACCTextStickerBGColorRadius
                if (currentLineRect.size.width > nextLineRect.size.width) {
                    lineRectArray[i] = @(CGRectMake(currentLineRect.origin.x, currentLineRect.origin.y, currentLineRect.size.width, currentLineRect.size.height + nextLineRect.size.height));
                } else {
                    lineRectArray[i] = @(CGRectMake(nextLineRect.origin.x, currentLineRect.origin.y, nextLineRect.size.width, currentLineRect.size.height + nextLineRect.size.height));
                }
                [lineRectArray removeObjectAtIndex:(i + 1)];
            } else {
                i ++;
            }
        }
        
        if (self.textAlignment == NSTextAlignmentLeft) {
            path = [self drawAlignmentLeftLineRectArray:lineRectArray];
        } else if (self.textAlignment == NSTextAlignmentRight) {
            path = [self drawAlignmentRightLineRectArray:lineRectArray];
        } else {
            path = [self drawAlignmentCenterLineRectArray:lineRectArray];
        }
    }
    
    if (self.textAlignment == NSTextAlignmentCenter || array.count == 1) {
        // Move to the origin first, then flip, and then move to the specified position
        UIBezierPath *reversingPath = path.bezierPathByReversingPath;
        CGRect boxRect = CGPathGetPathBoundingBox(reversingPath.CGPath);
        [reversingPath applyTransform:CGAffineTransformMakeTranslation(- CGRectGetMidX(boxRect), - CGRectGetMidY(boxRect))];
        [reversingPath applyTransform:CGAffineTransformMakeScale(-1, 1)];
        [reversingPath applyTransform:CGAffineTransformMakeTranslation(CGRectGetWidth(boxRect) + CGRectGetMidX(boxRect), CGRectGetMidY(boxRect))];
        [path appendPath:reversingPath];
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    leftLayer.path = path.CGPath;
    CGRect frame = self.bounds;
    frame.origin.x += kACCTextStickeTextViewContainerInset;
    frame.origin.y += kACCTextStickeTextViewContainerInset;
    leftLayer.frame = frame;
    [CATransaction commit];
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)leftTopWithRect_up:(CGRect)rect
{
    return CGPointMake(rect.origin.x - kACCTextStickerBGColorLeftMargin, rect.origin.y - kACCTextStickerBGColorTopMargin);
}

- (CGPoint)leftTopCenterWithRect_up:(CGRect)rect
{
    CGPoint leftTop = [self leftTopWithRect_up:rect];
    return CGPointMake(leftTop.x + kACCTextStickerBGColorRadius , leftTop.y + kACCTextStickerBGColorRadius);
}

- (CGPoint)leftTopWithRect_down:(CGRect)rect
{
    return CGPointMake(rect.origin.x - kACCTextStickerBGColorLeftMargin, rect.origin.y + kACCTextStickerBGColorTopMargin);
}

- (CGPoint)leftTopCenterWithRect_down:(CGRect)rect
{
    CGPoint leftTop = [self leftTopWithRect_down:rect];
    return CGPointMake(leftTop.x - kACCTextStickerBGColorRadius, leftTop.y + kACCTextStickerBGColorRadius);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)leftBottomWithRect_up:(CGRect)rect
{
    return CGPointMake(rect.origin.x - kACCTextStickerBGColorLeftMargin, rect.origin.y + rect.size.height - kACCTextStickerBGColorTopMargin);
}

- (CGPoint)leftBottomCenterWithRect_up:(CGRect)rect
{
    CGPoint leftBottomPoint = [self leftBottomWithRect_up:rect];
    return CGPointMake(leftBottomPoint.x - kACCTextStickerBGColorRadius, leftBottomPoint.y - kACCTextStickerBGColorRadius);
}

- (CGPoint)leftBottomWithRect_down:(CGRect)rect
{
    return CGPointMake(rect.origin.x - kACCTextStickerBGColorLeftMargin, rect.origin.y + rect.size.height + kACCTextStickerBGColorTopMargin);
}

- (CGPoint)leftBottomCenterWithRect_down:(CGRect)rect
{
    CGPoint leftBottomPoint = [self leftBottomWithRect_down:rect];
    return CGPointMake(leftBottomPoint.x + kACCTextStickerBGColorRadius, leftBottomPoint.y - kACCTextStickerBGColorRadius);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)topMidPointWithRect:(CGRect)rect
{
    return CGPointMake(CGRectGetMidX(rect), rect.origin.y - kACCTextStickerBGColorTopMargin);
}

- (CGPoint)bottomMidPointWithRect:(CGRect)rect
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect) + kACCTextStickerBGColorTopMargin);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)rightTopWithRect_up:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect) + kACCTextStickerBGColorLeftMargin, rect.origin.y - kACCTextStickerBGColorTopMargin);
}

- (CGPoint)rightTopCenterWithRect_up:(CGRect)rect
{
    CGPoint rightTop = [self rightTopWithRect_up:rect];
    return CGPointMake(rightTop.x - kACCTextStickerBGColorRadius , rightTop.y + kACCTextStickerBGColorRadius);
}

- (CGPoint)rightTopWithRect_down:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect) + kACCTextStickerBGColorLeftMargin, rect.origin.y + kACCTextStickerBGColorTopMargin);
}

- (CGPoint)rightTopCenterWithRect_down:(CGRect)rect
{
    CGPoint rightTop = [self rightTopWithRect_down:rect];
    return CGPointMake(rightTop.x + kACCTextStickerBGColorRadius , rightTop.y + kACCTextStickerBGColorRadius);
}

////////////////////////////////////////////////////////////////////////////////

- (CGPoint)rightBottomWithRect_up:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect) + kACCTextStickerBGColorLeftMargin, CGRectGetMaxY(rect) - kACCTextStickerBGColorTopMargin);
}

- (CGPoint)rightBottomCenterWithRect_up:(CGRect)rect
{
    CGPoint rightBottom = [self rightBottomWithRect_up:rect];
    return CGPointMake(rightBottom.x + kACCTextStickerBGColorRadius , rightBottom.y - kACCTextStickerBGColorRadius);
}

- (CGPoint)rightBottomWithRect_down:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect) + kACCTextStickerBGColorLeftMargin, CGRectGetMaxY(rect) + kACCTextStickerBGColorTopMargin);
}

- (CGPoint)rightBottomCenterWithRect_down:(CGRect)rect
{
    CGPoint rightBottom = [self rightBottomWithRect_down:rect];
    return CGPointMake(rightBottom.x - kACCTextStickerBGColorRadius , rightBottom.y - kACCTextStickerBGColorRadius);
}

////////////////////////////////////////////////////////////////////////////////

- (UIBezierPath *)drawAlignmentCenterLineRectArray:(NSArray<NSValue *> *)lineRectArray
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect firstLineRect = lineRectArray[0].CGRectValue;
    
    CGPoint topMidPoint = [self topMidPointWithRect:firstLineRect];
    [path moveToPoint:topMidPoint];
    
    CGPoint leftTop = [self leftTopWithRect_up:firstLineRect];
    CGPoint leftTopCenter = [self leftTopCenterWithRect_up:firstLineRect];
    [path addLineToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
    [path addArcWithCenter:leftTopCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI * 1.5 endAngle:M_PI clockwise:NO];
    
    for (int i = 0; i < lineRectArray.count; i++) {
        CGRect currentLineRect = lineRectArray[i].CGRectValue;
        if (i + 1 < lineRectArray.count) {
            //当前行是中间行
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            CGPoint nextLineLeftTopPoint;
            CGPoint nextLineLeftTopCenter;
            if (nextLineRect.origin.x > currentLineRect.origin.x) {
                leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
                leftBottomCenter = [self leftBottomCenterWithRect_down:currentLineRect];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
                
                nextLineLeftTopPoint = [self leftTopWithRect_down:nextLineRect];
                nextLineLeftTopCenter = [self leftTopCenterWithRect_down:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kACCTextStickerBGColorRadius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            } else {
                leftBottomPoint = [self leftBottomWithRect_up:currentLineRect];
                leftBottomCenter = [self leftBottomCenterWithRect_up:currentLineRect];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kACCTextStickerBGColorRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
                
                nextLineLeftTopPoint = [self leftTopWithRect_up:nextLineRect];
                nextLineLeftTopCenter = [self leftTopCenterWithRect_up:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kACCTextStickerBGColorRadius startAngle:1.5 * M_PI endAngle:M_PI clockwise:NO];
            }
        } else {
            // The last line
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
            leftBottomCenter = [self leftBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
            [path addArcWithCenter:leftBottomCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
            
            CGPoint bottomMidPoint = [self bottomMidPointWithRect:currentLineRect];
            [path addLineToPoint:CGPointMake(topMidPoint.x, bottomMidPoint.y)];
        }
    }
    
    return path;
}

- (UIBezierPath *)drawAlignmentLeftLineRectArray:(NSArray<NSValue *> *)lineRectArray
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect firstLineRect = lineRectArray[0].CGRectValue;
    
    CGPoint leftTop = [self leftTopWithRect_up:firstLineRect];
    CGPoint leftTopCenter = [self leftTopCenterWithRect_up:firstLineRect];
    
    [path moveToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
    
    CGPoint rightTop = [self rightTopWithRect_up:firstLineRect];
    CGPoint rightTopCenter = [self rightTopCenterWithRect_up:firstLineRect];
    [path addLineToPoint:CGPointMake(rightTopCenter.x, rightTop.y)];
    [path addArcWithCenter:rightTopCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI * 1.5 endAngle:M_PI * 2 clockwise:YES];
    
    for (int i = 0; i < lineRectArray.count; i++) {
        CGRect currentLineRect = lineRectArray[i].CGRectValue;
        if (i + 1 < lineRectArray.count) {
            // The middle line
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            
            CGPoint rightBottomPoint;
            CGPoint rightBottomCenter;
            CGPoint nextLineRightTopPoint;
            CGPoint nextLineRightTopCenter;
            if (nextLineRect.size.width < currentLineRect.size.width) {
                rightBottomPoint = [self rightBottomWithRect_down:currentLineRect];
                rightBottomCenter = [self rightBottomCenterWithRect_down:currentLineRect];
                [path addLineToPoint:CGPointMake(rightBottomPoint.x, rightBottomCenter.y)];
                [path addArcWithCenter:rightBottomCenter radius:kACCTextStickerBGColorRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
                
                nextLineRightTopPoint = [self rightTopWithRect_down:nextLineRect];
                nextLineRightTopCenter = [self rightTopCenterWithRect_down:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineRightTopCenter.x, nextLineRightTopPoint.y)];
                [path addArcWithCenter:nextLineRightTopCenter radius:kACCTextStickerBGColorRadius startAngle:1.5 * M_PI endAngle:M_PI clockwise:NO];
            } else {
                rightBottomPoint = [self rightBottomWithRect_up:currentLineRect];
                rightBottomCenter = [self rightBottomCenterWithRect_up:currentLineRect];
                [path addLineToPoint:CGPointMake(rightBottomPoint.x, rightBottomCenter.y)];
                [path addArcWithCenter:rightBottomCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
                
                nextLineRightTopPoint = [self rightTopWithRect_up:nextLineRect];
                nextLineRightTopCenter = [self rightTopCenterWithRect_up:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineRightTopCenter.x, nextLineRightTopPoint.y)];
                [path addArcWithCenter:nextLineRightTopCenter radius:kACCTextStickerBGColorRadius startAngle:1.5 * M_PI endAngle:M_PI * 2 clockwise:YES];
            }
        } else {
            // The last Line
            CGPoint rightBottomPoint;
            CGPoint rightBottomCenter;
            rightBottomPoint = [self rightBottomWithRect_down:currentLineRect];
            rightBottomCenter = [self rightBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(rightBottomPoint.x, rightBottomCenter.y)];
            [path addArcWithCenter:rightBottomCenter radius:kACCTextStickerBGColorRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
            
            CGPoint leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
            CGPoint leftBottomCenterPoint = [self leftBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(leftBottomCenterPoint.x, leftBottomPoint.y)];
            [path addArcWithCenter:leftBottomCenterPoint radius:kACCTextStickerBGColorRadius startAngle:M_PI * 0.5 endAngle:M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(leftTop.x, leftTopCenter.y)];
            [path addArcWithCenter:leftTopCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI endAngle:1.5 * M_PI clockwise:YES];
        }
    }
    
    return path;
}

- (UIBezierPath *)drawAlignmentRightLineRectArray:(NSArray<NSValue *> *)lineRectArray
{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect firstLineRect = lineRectArray[0].CGRectValue;
    
    CGPoint rightTopPoint = [self rightTopWithRect_up:firstLineRect];
    CGPoint rightTopCenterPoint = [self rightTopCenterWithRect_up:firstLineRect];
    
    [path moveToPoint:CGPointMake(rightTopCenterPoint.x, rightTopPoint.y)];
    
    CGPoint leftTop = [self leftTopWithRect_up:firstLineRect];
    CGPoint leftTopCenter = [self leftTopCenterWithRect_up:firstLineRect];
    [path addLineToPoint:CGPointMake(leftTopCenter.x, leftTop.y)];
    [path addArcWithCenter:leftTopCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI * 1.5 endAngle:M_PI clockwise:NO];
    
    for (int i = 0; i < lineRectArray.count; i++) {
        CGRect currentLineRect = lineRectArray[i].CGRectValue;
        if (i + 1 < lineRectArray.count) {
            // The middle line
            CGRect nextLineRect = lineRectArray[i + 1].CGRectValue;
            
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            CGPoint nextLineLeftTopPoint;
            CGPoint nextLineLeftTopCenter;
            if (nextLineRect.origin.x > currentLineRect.origin.x) {
                leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
                leftBottomCenter = [self leftBottomCenterWithRect_down:currentLineRect];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
                
                nextLineLeftTopPoint = [self leftTopWithRect_down:nextLineRect];
                nextLineLeftTopCenter = [self leftTopCenterWithRect_down:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kACCTextStickerBGColorRadius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            } else {
                leftBottomPoint = [self leftBottomWithRect_up:currentLineRect];
                leftBottomCenter = [self leftBottomCenterWithRect_up:currentLineRect];
                [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
                [path addArcWithCenter:leftBottomCenter radius:kACCTextStickerBGColorRadius startAngle:0 endAngle:M_PI * 0.5 clockwise:YES];
                
                nextLineLeftTopPoint = [self leftTopWithRect_up:nextLineRect];
                nextLineLeftTopCenter = [self leftTopCenterWithRect_up:nextLineRect];
                [path addLineToPoint:CGPointMake(nextLineLeftTopCenter.x, nextLineLeftTopPoint.y)];
                [path addArcWithCenter:nextLineLeftTopCenter radius:kACCTextStickerBGColorRadius startAngle:1.5 * M_PI endAngle:M_PI clockwise:NO];
            }
        } else {
            // The last line
            CGPoint leftBottomPoint;
            CGPoint leftBottomCenter;
            leftBottomPoint = [self leftBottomWithRect_down:currentLineRect];
            leftBottomCenter = [self leftBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(leftBottomPoint.x, leftBottomCenter.y)];
            [path addArcWithCenter:leftBottomCenter radius:kACCTextStickerBGColorRadius startAngle:M_PI endAngle:M_PI * 0.5 clockwise:NO];
            
            CGPoint rightBottomPoint = [self rightBottomWithRect_down:currentLineRect];
            CGPoint rightBottomCenterPoint = [self rightBottomCenterWithRect_down:currentLineRect];
            [path addLineToPoint:CGPointMake(rightBottomCenterPoint.x, rightBottomPoint.y)];
            [path addArcWithCenter:rightBottomCenterPoint radius:kACCTextStickerBGColorRadius startAngle:M_PI * 0.5 endAngle:0 clockwise:NO];
            [path addLineToPoint:CGPointMake(rightTopPoint.x, rightTopCenterPoint.y)];
            [path addArcWithCenter:rightTopCenterPoint radius:kACCTextStickerBGColorRadius startAngle:2 * M_PI endAngle:1.5 * M_PI clockwise:NO];
        }
    }
    
    return path;
}

- (instancetype)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    ACCEditPageLayoutManager *acc_layoutManager = [ACCEditPageLayoutManager new];
    acc_layoutManager.usesFontLeading = NO;
    ACCEditPageTextStorage *acc_textStorage = [ACCEditPageTextStorage new];
    [acc_layoutManager addTextContainer:textContainer];
    [acc_textStorage addLayoutManager:acc_layoutManager];
    
    self = [super initWithFrame:frame textContainer:textContainer];
    if (self) {
        _acc_layoutManager = acc_layoutManager;
        _acc_textStorage = acc_textStorage;
        [self.acc_textStorage setTextView:self];
    }
    return self;
}

@end
