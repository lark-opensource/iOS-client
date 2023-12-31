//
//  AWESwitchRecordModeCollectionView.m
//  AWEStudio
//
//  Created by jindulys on 2018/12/11.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWESwitchRecordModeCollectionView.h"

@interface AWESwitchRecordModeCollectionView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

@end

@implementation AWESwitchRecordModeCollectionView
@synthesize initialContentOffset = _initialContentOffset;
@synthesize isTouching = _isTouching;
@synthesize needKeepInitialContentOffsetBlock = _needKeepInitialContentOffsetBlock;
@synthesize selectedIndex = _selectedIndex;
@synthesize touchDelegate = _touchDelegate;

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        UITapGestureRecognizer *tapGestureRecognizer =
                [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        _tapGestureRecognizer = tapGestureRecognizer;
        _tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:tapGestureRecognizer];
        UILongPressGestureRecognizer *longPressRecognizer =
                [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
        _longPressRecognizer = longPressRecognizer;
        _longPressRecognizer.delegate = self;
        _longPressRecognizer.minimumPressDuration = 0.2;
        _initialContentOffset = CGPointZero;
        [self addGestureRecognizer:longPressRecognizer];
    }
    return self;
}

- (void)setContentOffset:(CGPoint)contentOffset
{
    if (!CGPointEqualToPoint(self.initialContentOffset, CGPointZero)){
        if (self.needKeepInitialContentOffsetBlock != nil) {
            if (self.needKeepInitialContentOffsetBlock()) {
                contentOffset = self.initialContentOffset;
            }
        }
    }
    [super setContentOffset:contentOffset];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.isTouching = YES;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    self.isTouching = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    self.isTouching = NO;
}

#pragma mark - Protocols
#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:touchPoint];
    if (gestureRecognizer == self.tapGestureRecognizer) {
        BOOL delegateShouldRecTap = NO;
        if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(shouldRecognizeTapGestureWithView:touchPoint:)]) {
            // 需要判断是否需要点击生效
            delegateShouldRecTap = [self.touchDelegate shouldRecognizeTapGestureWithView:self touchPoint:touchPoint];
        }
        if (indexPath == nil) {
            // 如果点击到某个cell的空隙处，需要手动选择对应的cell
            NSArray *visibleCells = [self visibleCells];
            CGFloat minSpacing = MAXFLOAT;
            NSIndexPath *shouldSelectedIndexPath;
            for (UICollectionViewCell *cell in visibleCells) {
                CGFloat centerX = cell.frame.origin.x + cell.frame.size.width / 2.0;
                CGFloat spacing = ABS(centerX - touchPoint.x);
                if (spacing < minSpacing) {
                    minSpacing = spacing;
                    shouldSelectedIndexPath = [self indexPathForCell:cell];
                }
            }
            if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(shouldAdjustSelectedIndexToIndex:withView:)]) {
                [self.touchDelegate shouldAdjustSelectedIndexToIndex:shouldSelectedIndexPath withView:self];
            }
        } else if (indexPath.item == self.selectedIndex && delegateShouldRecTap) {
            // 在zoom模式下，如果选中了已选择的cell，需要做特殊处理
            return YES;
        }
        return NO;
    } else if (gestureRecognizer == self.longPressRecognizer) {
        BOOL delegateShouldRec = YES;
        if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(shouldRecognizeLongPressGestureWithView:touchPoint:)]) {
            // 需要判断是否需要长按生效
            delegateShouldRec = [self.touchDelegate shouldRecognizeLongPressGestureWithView:self touchPoint:touchPoint];
        }
        if (indexPath &&
            indexPath.item == self.selectedIndex &&
            delegateShouldRec) {
            return YES;
        }
        return NO;
    }
    // 对于collectionview，有自带的pangesturerecognizer，需要返回YES
    BOOL shouldResponsePan = YES;
    if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(shouldRecognizePanGestureWithView:)]) {
        // 需要判断是否允许pan生效
        shouldResponsePan = [self.touchDelegate shouldRecognizePanGestureWithView:self];
    }
    return shouldResponsePan;
}

#pragma mark - Private

- (void)tap:(UITapGestureRecognizer *)taprec
{
    switch (taprec.state) {
        case UIGestureRecognizerStateBegan:
            self.isTouching = YES;
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            self.isTouching = NO;
            break;
        default:
            break;
    }
    if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(switchRecordModeCollectionViewTappedWithView:)]) {
        [self.touchDelegate switchRecordModeCollectionViewTappedWithView:self];
    }
}

- (void)longPressed:(UILongPressGestureRecognizer *)longRec
{
    switch (longRec.state) {
        case UIGestureRecognizerStateBegan:
            self.isTouching = YES;
            if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(switchRecordModeCollectionViewPressStartWithView:)]) {
                [self.touchDelegate switchRecordModeCollectionViewPressStartWithView:self];
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(switchRecordModeCollectionViewPressMove:WithView:)]) {
                [self.touchDelegate switchRecordModeCollectionViewPressMove:[longRec locationInView:self] WithView:self];
            }
            break;
        case UIGestureRecognizerStateEnded:
            self.isTouching = NO;
            if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(switchRecordModeCollectionViewPressEndWithView:)]) {
                [self.touchDelegate switchRecordModeCollectionViewPressEndWithView:self];
            }
            break;
        case UIGestureRecognizerStateCancelled:
            self.isTouching = NO;
            if (self.touchDelegate && [self.touchDelegate respondsToSelector:@selector(switchRecordModeCollectionViewCancelledWithView:)]) {
                [self.touchDelegate switchRecordModeCollectionViewCancelledWithView:self];
            }
            break;
        case UIGestureRecognizerStateFailed:
            self.isTouching = NO;
            break;
        default:
            break;
    }
}

@end
