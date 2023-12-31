//
//  CJPayTouchLabel.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/21.
//

#import "CJPayTouchLabel.h"

#import "CJPayUIMacro.h"

#import <CoreText/CoreText.h>

@interface CJAttributeModel : NSObject

@property (nonatomic, copy) NSString *str;
@property (nonatomic) NSRange range;

@end

@implementation CJAttributeModel

@end

@interface CJPayTouchLabel() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray *attributeStrings;
@property (nonatomic, strong) NSMutableDictionary *effectDic;
@property (nonatomic, copy) CJPayTouchLabelTapBlock tapBlock;

@end

@implementation CJPayTouchLabel

#pragma mark - mainFunction
- (void)cj_addAttributeTapActionWithStrings:(NSArray <NSString *> *)strings tapClicked:(CJPayTouchLabelTapBlock)tapClick
{
    [self p_removeAttributeTapActions];
    [self p_getRangesWithStrings:strings];
    self.userInteractionEnabled = YES;
    
    if (self.tapBlock != tapClick) {
        self.tapBlock = tapClick;
    }
}

- (void)p_removeAttributeTapActions
{
    self.tapBlock = nil;
    self.effectDic = nil;
    self.attributeStrings = [NSMutableArray array];
}

#pragma mark - touchAction
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    
    CGPoint point = [touch locationInView:self];

    @CJWeakify(self)
    
    BOOL ret = [self p_getTapFrameWithTouchPoint:point result:^(NSString *string, NSRange range, NSInteger index) {
        CJ_CALL_BLOCK(weak_self.tapBlock, weak_self, string, range, index);
    }];
    if (!ret) {
        [super touchesBegan:touches withEvent:event];
    }
}

#pragma mark - getTapFrame
- (BOOL)p_getTapFrameWithTouchPoint:(CGPoint)point result:(void (^) (NSString *string , NSRange range , NSInteger index))resultBlock
{
    CGMutablePathRef route = CGPathCreateMutable();
    CGPathAddRect(route, NULL, CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height + 20));
    CTFramesetterRef frSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)self.attributedText);
    CTFrameRef fr = CTFramesetterCreateFrame(frSetter, CFRangeMake(0, 0), route, NULL);
    CGFloat total_height =  [self p_textSizeWithAttributedString:self.attributedText width:self.bounds.size.width numberOfLines:0].height;
    CFArrayRef vector = CTFrameGetLines(fr);
    if (!vector) {
        CFRelease(frSetter);
        CGPathRelease(route);
        CFRelease(fr);
        return NO;
    }
    CFIndex cnt = CFArrayGetCount(vector);
    CGPoint oldPoint[cnt];
    CTFrameGetLineOrigins(fr, CFRangeMake(0, 0), oldPoint);
    CFIndex i_ = 0;
    while(i_ < cnt){
        CTLineRef lineRef = CFArrayGetValueAtIndex(vector, i_);
        CGRect lineBounds = [self p_getLineBounds:lineRef point:oldPoint[i_]];
        CGFloat lineOutSpace = (self.bounds.size.height - total_height) / 2;
        CGRect Re = CGRectApplyAffineTransform(lineBounds, [self p_transformForCoreText]);
        Re.origin.y = lineOutSpace + [self p_getLineOrign:lineRef];
        Re.origin.y -= 5;
        Re.size.height += 10;
        if (CGRectContainsPoint(Re, point)) {
            CGPoint tmpPoint = CGPointMake(point.x - CGRectGetMinX(Re), point.y - CGRectGetMinY(Re));
            CGFloat diff;
            CFIndex idx = CTLineGetStringIndexForPosition(lineRef, tmpPoint);
            CTLineGetOffsetForStringIndex(lineRef, idx, &diff);
            if (diff > tmpPoint.x) {
                idx -= 1;
            }
            NSInteger cnt_l = self.attributeStrings.count;
            for (int j = 0; j < cnt_l; j++) {
                CJAttributeModel *md = self.attributeStrings[j];
                NSRange rang_l = md.range;
                if (NSLocationInRange(idx, rang_l)) {
                    CJ_CALL_BLOCK(resultBlock, md.str, md.range, (NSInteger)j);
                    CFRelease(fr);
                    CFRelease(frSetter);
                    CGPathRelease(route);
                    return YES;
                }
            }
        }
        i_++;
    }
    CGPathRelease(route);
    CFRelease(fr);
    CFRelease(frSetter);
    return NO;
}

- (CGAffineTransform)p_transformForCoreText
{
    return CGAffineTransformScale(CGAffineTransformMakeTranslation(0, self.bounds.size.height), 1.f, -1.f);
}

- (CGRect)p_getLineBounds:(CTLineRef)line point:(CGPoint)point
{
    CGFloat ascent = 0.0f;
    CGFloat descent = 0.0f;
    CGFloat leading = 0.0f;
    CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    CGFloat height = 0.0f;
    
    CFRange range = CTLineGetStringRange(line);
    NSAttributedString * attributedString = [self.attributedText attributedSubstringFromRange:NSMakeRange(range.location, range.length)];
    if ([attributedString.string hasSuffix:@"\n"] && attributedString.string.length > 1) {
        attributedString = [attributedString attributedSubstringFromRange:NSMakeRange(0, attributedString.length - 1)];
    }
    height = [self p_textSizeWithAttributedString:attributedString width:self.bounds.size.width numberOfLines:0].height;
    return CGRectMake(point.x, point.y , width, height);
}

- (CGFloat)p_getLineOrign:(CTLineRef)line
{
    CFRange range = CTLineGetStringRange(line);
    if (range.location == 0) {
        return 0.0f;
    }else {
        NSAttributedString * attributedString = [self.attributedText attributedSubstringFromRange:NSMakeRange(0, range.location)];
        if ([attributedString.string hasSuffix:@"\n"] && attributedString.string.length > 1) {
            attributedString = [attributedString attributedSubstringFromRange:NSMakeRange(0, attributedString.length - 1)];
        }
        return [self p_textSizeWithAttributedString:attributedString width:self.bounds.size.width numberOfLines:0].height;
    }
}

- (CGSize)p_textSizeWithAttributedString:(NSAttributedString *)attributedString width:(float)width numberOfLines:(NSInteger)numberOfLines
{
    @autoreleasepool {
        UILabel *sizeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        sizeLabel.numberOfLines = numberOfLines;
        sizeLabel.attributedText = attributedString;
        CGSize fitSize = [sizeLabel sizeThatFits:CGSizeMake(width, MAXFLOAT)];
        return fitSize;
    }
}

#pragma mark - getRange
- (void)p_getRangesWithStrings:(NSArray <NSString *>  *)sstr
{
    if (self.attributedText == nil) return;
    __block  NSString *str = self.attributedText.string;
    self.attributeStrings = [NSMutableArray array];
    @CJWeakify(self)
    [sstr enumerateObjectsUsingBlock:^(NSString * _Nonnull ss_o, NSUInteger idx, BOOL * _Nonnull flag) {
        NSRange rg = [str rangeOfString:ss_o];
        if (rg.length > 0) {
            str = [str stringByReplacingCharactersInRange:rg withString:[weak_self p_getStringWithRange:rg]];
            CJAttributeModel *md = [CJAttributeModel new];
            md.range = rg;
            md.str = ss_o;
            [weak_self.attributeStrings addObject:md];
        }
    }];
}

- (NSString *)p_getStringWithRange:(NSRange)rag
{
    NSMutableString *str = [NSMutableString string];
    int i = 0;
    while(i < rag.length) {
        [str appendString:@" "];
        ++i;
    }
    return str;
}

@end
