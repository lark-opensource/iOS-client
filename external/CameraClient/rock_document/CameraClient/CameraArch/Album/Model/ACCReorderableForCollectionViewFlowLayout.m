//
//  ACCReorderableForCollectionViewFlowLayout.m
//  AWEStudio
//
//  Created by 旭旭 on 2018/5/18.
//  Copyright © 2018年 bytedance. All rights reserved.
//


#import "ACCReorderableForCollectionViewFlowLayout.h"
#import <objc/runtime.h>

static inline CGPoint AWECGPointAdd(CGPoint point1, CGPoint point2)
{
    return CGPointMake(point1.x + point2.x, point1.y + point2.y);
}

typedef NS_ENUM(NSInteger, ACCReorderableForScrollingDirection) {
    ACCReorderableForScrollingDirectionUnknown = 0,
    ACCReorderableForScrollingDirectionUp,
    ACCReorderableForScrollingDirectionDown,
    ACCReorderableForScrollingDirectionLeft,
    ACCReorderableForScrollingDirectionRight
};

static NSString * const kACCReorderableForScrollingDirectionKey = @"kACCReorderableForScrollingDirection";
static NSString * const kACCReorderableForCollectionViewKeyPath = @"collectionView";


#pragma mark - CADisplayLink extension

@interface CADisplayLink (accReorderableCollectionViewFlowLayoutUseInfo)

@property (nonatomic, copy) NSDictionary *awe_reorderUserInfo;

@end

@implementation CADisplayLink (accReorderableCollectionViewFlowLayoutUseInfo)

- (void)setAwe_reorderUserInfo:(NSDictionary *)awe_ReorderUserInfo
{
    objc_setAssociatedObject(self, @selector(awe_reorderUserInfo), awe_ReorderUserInfo, OBJC_ASSOCIATION_COPY);
}

- (NSDictionary *)awe_reorderUserInfo
{
    return objc_getAssociatedObject(self, @selector(awe_reorderUserInfo));
}

@end

#pragma mark - UICollectionViewCell extension

@interface UICollectionViewCell (accReorderableCollectionViewFlowLayout)

- (UIView *)awe_reorderableSnapshotView;

@end

@implementation UICollectionViewCell (accReorderableCollectionViewFlowLayout)

- (UIView *)awe_reorderableSnapshotView {
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        return [self snapshotViewAfterScreenUpdates:YES];
    } else {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0f);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return [[UIImageView alloc] initWithImage:image];
    }
}

@end

#pragma mark - Pass Touch View
@implementation AWEPassTouchView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self){
        if (event.allTouches.count == 1 && event.allTouches.anyObject == self.passTouch) {
            return nil;
        }
        return self;
    }
    return hitView;
}

@end

#pragma mark -

@interface ACCReorderableForCollectionViewFlowLayout ()

@property (strong, nonatomic) NSIndexPath *selectedItemIndexPath;
@property (strong, nonatomic) UIView *currentView;
@property (assign, nonatomic) CGPoint currentViewCenter;
@property (assign, nonatomic) CGPoint originalCellCenter;
@property (assign, nonatomic) CGPoint panTranslationInCollectionView;
@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) UITouch *activeTouch;
@property (strong, nonatomic) UITouch *recentTouch;
@property (strong, nonatomic) AWEPassTouchView *passTouchView;
@property (weak, nonatomic, readonly) id<ACCReorderableForCollectionViewDataSource> dataSource;
@property (weak, nonatomic, readonly) id<ACCReorderableForCollectionViewDelegateFlowLayout> delegate;
@property (strong, nonatomic) UIImpactFeedbackGenerator *feedbackGenerator NS_AVAILABLE_IOS(10_0);

@end

@implementation ACCReorderableForCollectionViewFlowLayout

- (id)init
{
    self = [super init];
    if (self) {
        [self setDefaults];
        [self addObserver:self forKeyPath:kACCReorderableForCollectionViewKeyPath options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc
{
    [self invalidatesScrollTimer];
    [self tearDownCollectionView];
    [self removeObserver:self forKeyPath:kACCReorderableForCollectionViewKeyPath];
}

- (void)setDefaults
{
    _scrollingSpeed = 300.0f;
    _scrollingTriggerEdgeInsets = UIEdgeInsetsMake(50.0f, 50.0f, 50.0f, 50.0f);
    _oneDirectionOnly = NO;
    _draggableInset = UIEdgeInsetsZero;
    _highlightedScale = 1.25;
    _hapticFeedbackEnabled = NO;
    _disableLongAndPanGesture = NO;
}

- (void)setupCollectionView
{
    if (self.disableLongAndPanGesture) {
        return;
    }
    
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(handleLongPressGesture:)];
    _longPressGestureRecognizer.delegate = self;
    
    // Links the default long press gesture recognizer to the custom long press gesture recognizer we are creating now
    // by enforcing failure dependency so that they doesn't clash.
    for (UIGestureRecognizer *gestureRecognizer in self.collectionView.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }
    
    [self.collectionView addGestureRecognizer:_longPressGestureRecognizer];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(handlePanGesture:)];
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    _panGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:_panGestureRecognizer];

    // Useful in multiple scenarios: one common scenario being when the Notification Center drawer is pulled down
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleApplicationWillResignActive:) name: UIApplicationWillResignActiveNotification object:nil];
}

- (void)tearDownCollectionView
{
    // Tear down long press gesture
    if (_longPressGestureRecognizer) {
        UIView *view = _longPressGestureRecognizer.view;
        if (view) {
            [view removeGestureRecognizer:_longPressGestureRecognizer];
        }
        _longPressGestureRecognizer.delegate = nil;
        _longPressGestureRecognizer = nil;
    }
    
    // Tear down pan gesture
    if (_panGestureRecognizer) {
        UIView *view = _panGestureRecognizer.view;
        if (view) {
            [view removeGestureRecognizer:_panGestureRecognizer];
        }
        _panGestureRecognizer.delegate = nil;
        _panGestureRecognizer = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}


- (AWEPassTouchView *)passTouchView {
    if (_passTouchView == nil) {
        _passTouchView = [[AWEPassTouchView alloc] initWithFrame:CGRectZero];
    }
    return _passTouchView;
}

- (void)setupPassTouchViewWithTouch: (UITouch *)touch {
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self.passTouchView];
    self.passTouchView.frame = window.bounds;
    self.passTouchView.passTouch = touch;
}

- (void)tearDownPassTouchView {
    [self.passTouchView removeFromSuperview];
    self.passTouchView.passTouch = nil;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    if ([layoutAttributes.indexPath isEqual:self.selectedItemIndexPath]) {
        layoutAttributes.hidden = YES;
    }
}

- (id<ACCReorderableForCollectionViewDataSource>)dataSource
{
    return (id<ACCReorderableForCollectionViewDataSource>)self.collectionView.dataSource;
}

- (id<ACCReorderableForCollectionViewDelegateFlowLayout>)delegate
{
    return (id<ACCReorderableForCollectionViewDelegateFlowLayout>)self.collectionView.delegate;
}

- (CGPoint)regulatedCenter: (CGPoint)center {
    CGFloat halfWidth = self.currentView.bounds.size.width * 0.5 * self.highlightedScale;
    CGFloat halfHeight = self.currentView.bounds.size.height * 0.5 * self.highlightedScale;
    CGFloat x = MIN(CGRectGetMaxX(self.collectionView.bounds) - self.draggableInset.right - halfWidth,
                     MAX(center.x, CGRectGetMinX(self.collectionView.bounds) + self.draggableInset.left + halfWidth));
    CGFloat y = MIN(CGRectGetMaxY(self.collectionView.bounds) - self.draggableInset.bottom - halfHeight,
                    MAX(center.y, CGRectGetMinY(self.collectionView.bounds) + self.draggableInset.top + halfHeight));
    return CGPointMake(x, y);
}

- (void)invalidateLayoutIfNecessary
{
    CGPoint point;
    if (self.oneDirectionOnly) {
        switch (self.scrollDirection) {
            case UICollectionViewScrollDirectionVertical:
                point = CGPointMake(self.originalCellCenter.x, self.currentView.center.y);
                break;
            case UICollectionViewScrollDirectionHorizontal:
                point = CGPointMake(self.currentView.center.x, self.originalCellCenter.y);
                break;
        }
    } else {
        point = self.currentView.center;
    }
    NSIndexPath *newIndexPath = [self.collectionView indexPathForItemAtPoint:point];
    NSIndexPath *previousIndexPath = self.selectedItemIndexPath;
    
    if ((newIndexPath == nil) || (previousIndexPath == nil) || [newIndexPath isEqual:previousIndexPath]) {
        return;
    }
    
    if ([self.dataSource respondsToSelector:@selector(accReorderableCollectionView:itemAtIndexPath:canMoveToIndexPath:)] &&
        ![self.dataSource accReorderableCollectionView:self.collectionView itemAtIndexPath:previousIndexPath canMoveToIndexPath:newIndexPath]) {
        return;
    }
    
    self.selectedItemIndexPath = newIndexPath;
    
    if ([self.dataSource respondsToSelector:@selector(accReorderableCollectionView:itemAtIndexPath:willMoveToIndexPath:)]) {
        [self.dataSource accReorderableCollectionView:self.collectionView itemAtIndexPath:previousIndexPath willMoveToIndexPath:newIndexPath];
    }
    [self hapticFeedback];

    __weak typeof(self) weakSelf = self;
    [self.collectionView performBatchUpdates:^{
        __strong typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf.collectionView deleteItemsAtIndexPaths:@[previousIndexPath]];
            [strongSelf.collectionView insertItemsAtIndexPaths:@[newIndexPath]];
        }
    } completion:^(BOOL finished) {
        __strong typeof(self) strongSelf = weakSelf;
        if ([strongSelf.dataSource respondsToSelector:@selector(accReorderableCollectionView:itemAtIndexPath:didMoveToIndexPath:)]) {
            [strongSelf.dataSource accReorderableCollectionView:strongSelf.collectionView itemAtIndexPath:previousIndexPath didMoveToIndexPath:newIndexPath];
        }
    }];
}

- (void)invalidatesScrollTimer
{
    if (!self.displayLink.paused) {
        [self.displayLink invalidate];
    }
    self.displayLink = nil;
}

- (void)setupScrollTimerInDirection:(ACCReorderableForScrollingDirection)direction
{
    if (!self.displayLink.paused) {
        ACCReorderableForScrollingDirection oldDirection = [self.displayLink.awe_reorderUserInfo[kACCReorderableForScrollingDirectionKey] integerValue];

        if (direction == oldDirection) {
            return;
        }
    }
    
    [self invalidatesScrollTimer];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleScroll:)];
    self.displayLink.awe_reorderUserInfo = @{ kACCReorderableForScrollingDirectionKey : @(direction) };

    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (UIImpactFeedbackGenerator *)feedbackGenerator {
    if (_feedbackGenerator == nil) {
        _feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    }
    return _feedbackGenerator;
}

- (void)hapticFeedback {
    if (self.hapticFeedbackEnabled) {
        if (@available(iOS 10.0, *)) {
            [self.feedbackGenerator impactOccurred];
        }
    }
}

#pragma mark - Target/Action methods

// Tight loop, allocate memory sparely, even if they are stack allocation.
- (void)handleScroll:(CADisplayLink *)displayLink
{
    ACCReorderableForScrollingDirection direction = (ACCReorderableForScrollingDirection)[displayLink.awe_reorderUserInfo[kACCReorderableForScrollingDirectionKey] integerValue];
    if (direction == ACCReorderableForScrollingDirectionUnknown) {
        return;
    }
    
    CGSize frameSize = self.collectionView.bounds.size;
    CGSize contentSize = self.collectionView.contentSize;
    CGPoint contentOffset = self.collectionView.contentOffset;
    UIEdgeInsets contentInset = self.collectionView.contentInset;
    // Important to have an integer `distance` as the `contentOffset` property automatically gets rounded
    // and it would diverge from the view's center resulting in a "cell is slipping away under finger"-bug.
    CGFloat distance = rint(self.scrollingSpeed * displayLink.duration);
    CGPoint translation = CGPointZero;
    
    switch(direction) {
        case ACCReorderableForScrollingDirectionUp: {
            distance = -distance;
            CGFloat minY = 0.0f - contentInset.top;
            
            if ((contentOffset.y + distance) <= minY) {
                distance = -contentOffset.y - contentInset.top;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case ACCReorderableForScrollingDirectionDown: {
            CGFloat maxY = MAX(contentSize.height, frameSize.height) - frameSize.height + contentInset.bottom;
            
            if ((contentOffset.y + distance) >= maxY) {
                distance = maxY - contentOffset.y;
            }
            
            translation = CGPointMake(0.0f, distance);
        } break;
        case ACCReorderableForScrollingDirectionLeft: {
            distance = -distance;
            CGFloat minX = 0.0f - contentInset.left;
            
            if ((contentOffset.x + distance) <= minX) {
                distance = -contentOffset.x - contentInset.left;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        case ACCReorderableForScrollingDirectionRight: {
            CGFloat maxX = MAX(contentSize.width, frameSize.width) - frameSize.width + contentInset.right;
            
            if ((contentOffset.x + distance) >= maxX) {
                distance = maxX - contentOffset.x;
            }
            
            translation = CGPointMake(distance, 0.0f);
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    self.currentViewCenter = AWECGPointAdd(self.currentViewCenter, translation);
    self.currentView.center = [self regulatedCenter: AWECGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView)];
    self.collectionView.contentOffset = AWECGPointAdd(contentOffset, translation);
}


- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    switch(gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan: {
            NSIndexPath *currentIndexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
            
            if (currentIndexPath == nil) {
                return;
            }
            
            if ([self.dataSource respondsToSelector:@selector(accReorderableCollectionView:canMoveItemAtIndexPath:)] &&
               ![self.dataSource accReorderableCollectionView:self.collectionView canMoveItemAtIndexPath:currentIndexPath]) {
                return;
            }
            self.activeTouch = self.recentTouch;
            [self setupPassTouchViewWithTouch:self.activeTouch];
            self.selectedItemIndexPath = currentIndexPath;
            
            if ([self.delegate respondsToSelector:@selector(accReorderableCollectionView:layout:willBeginDraggingItemAtIndexPath:)]) {
                [self.delegate accReorderableCollectionView:self.collectionView layout:self willBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
            [self hapticFeedback];
            
            UICollectionViewCell *collectionViewCell = [self.collectionView cellForItemAtIndexPath:self.selectedItemIndexPath];
            
            self.originalCellCenter = collectionViewCell.center;
            self.currentView = [[UIView alloc] initWithFrame:collectionViewCell.frame];
            
            collectionViewCell.highlighted = YES;
            UIView *highlightedImageView = [collectionViewCell awe_reorderableSnapshotView];
            highlightedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            highlightedImageView.alpha = 1.0f;
            
            collectionViewCell.highlighted = NO;
            UIView *imageView = [collectionViewCell awe_reorderableSnapshotView];
            imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            imageView.alpha = 0.0f;
            
            [self.currentView addSubview:imageView];
            [self.currentView addSubview:highlightedImageView];
            [self.collectionView addSubview:self.currentView];
            
            self.currentViewCenter = self.currentView.center;
            
            if ([self.delegate respondsToSelector:@selector(accReorderableCollectionView:layout:didBeginDraggingItemAtIndexPath:)]) {
                  [self.delegate accReorderableCollectionView:self.collectionView layout:self didBeginDraggingItemAtIndexPath:self.selectedItemIndexPath];
            }
        
            __weak typeof(self) weakSelf = self;
            [UIView
             animateWithDuration:0.3
             delay:0.0
             options:UIViewAnimationOptionBeginFromCurrentState
             animations:^{
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     strongSelf.currentView.transform = CGAffineTransformMakeScale(self.highlightedScale, self.highlightedScale);
                     highlightedImageView.alpha = 0.0f;
                     imageView.alpha = 1.0f;
                 }
             }
             completion:^(BOOL finished) {
                 __strong typeof(self) strongSelf = weakSelf;
                 if (strongSelf) {
                     [highlightedImageView removeFromSuperview];
                 }
             }];
            
            [self invalidateLayout];
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self tearDownPassTouchView];
            self.activeTouch = nil;
            NSIndexPath *currentIndexPath = self.selectedItemIndexPath;
            
            if (currentIndexPath) {
                if ([self.delegate respondsToSelector:@selector(accReorderableCollectionView:layout:willEndDraggingItemAtIndexPath:)]) {
                    [self.delegate accReorderableCollectionView:self.collectionView layout:self willEndDraggingItemAtIndexPath:currentIndexPath];
                }
                
                self.selectedItemIndexPath = nil;
                self.currentViewCenter = CGPointZero;
                
                UICollectionViewLayoutAttributes *layoutAttributes = [self layoutAttributesForItemAtIndexPath:currentIndexPath];
                
                self.longPressGestureRecognizer.enabled = NO;
                
                __weak typeof(self) weakSelf = self;
                [UIView
                 animateWithDuration:0.3
                 delay:0.0
                 options:UIViewAnimationOptionBeginFromCurrentState
                 animations:^{
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         strongSelf.currentView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
                         strongSelf.currentView.center = layoutAttributes.center;
                     }
                 }
                 completion:^(BOOL finished) {
                     
                     self.longPressGestureRecognizer.enabled = YES;
                     
                     __strong typeof(self) strongSelf = weakSelf;
                     if (strongSelf) {
                         [strongSelf.currentView removeFromSuperview];
                         strongSelf.currentView = nil;
                         [strongSelf invalidateLayout];
                         
                         if ([strongSelf.delegate respondsToSelector:@selector(accReorderableCollectionView:layout:didEndDraggingItemAtIndexPath:)]) {
                             [strongSelf.delegate accReorderableCollectionView:strongSelf.collectionView layout:strongSelf didEndDraggingItemAtIndexPath:currentIndexPath];
                         }
                     }
                 }];
            }
        } break;
            
        default: break;
    }
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged: {
            self.panTranslationInCollectionView = [gestureRecognizer translationInView:self.collectionView];
            CGPoint viewCenter = self.currentView.center = [self regulatedCenter: AWECGPointAdd(self.currentViewCenter, self.panTranslationInCollectionView)];
            
            [self invalidateLayoutIfNecessary];
            
            switch (self.scrollDirection) {
                case UICollectionViewScrollDirectionVertical: {
                    if (viewCenter.y < (CGRectGetMinY(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.top)) {
                        [self setupScrollTimerInDirection:ACCReorderableForScrollingDirectionUp];
                    } else {
                        if (viewCenter.y > (CGRectGetMaxY(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.bottom)) {
                            [self setupScrollTimerInDirection:ACCReorderableForScrollingDirectionDown];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
                case UICollectionViewScrollDirectionHorizontal: {
                    if (viewCenter.x < (CGRectGetMinX(self.collectionView.bounds) + self.scrollingTriggerEdgeInsets.left)) {
                        [self setupScrollTimerInDirection:ACCReorderableForScrollingDirectionLeft];
                    } else {
                        if (viewCenter.x > (CGRectGetMaxX(self.collectionView.bounds) - self.scrollingTriggerEdgeInsets.right)) {
                            [self setupScrollTimerInDirection:ACCReorderableForScrollingDirectionRight];
                        } else {
                            [self invalidatesScrollTimer];
                        }
                    }
                } break;
            }
        } break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            [self invalidatesScrollTimer];
        } break;
        default: {
            // Do nothing...
        } break;
    }
}

#pragma mark - UICollectionViewLayout overridden methods

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray *layoutAttributesForElementsInRect = [super layoutAttributesForElementsInRect:rect];
    
    for (UICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesForElementsInRect) {
        switch (layoutAttributes.representedElementCategory) {
            case UICollectionElementCategoryCell: {
                [self applyLayoutAttributes:layoutAttributes];
            } break;
            default: {
                // Do nothing...
            } break;
        }
    }
    
    return layoutAttributesForElementsInRect;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes *layoutAttributes = [super layoutAttributesForItemAtIndexPath:indexPath];
    
    switch (layoutAttributes.representedElementCategory) {
        case UICollectionElementCategoryCell: {
            [self applyLayoutAttributes:layoutAttributes];
        } break;
        default: {
            // Do nothing...
        } break;
    }
    
    return layoutAttributes;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return (self.selectedItemIndexPath != nil);
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if ([self.longPressGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.panGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    if ([self.panGestureRecognizer isEqual:gestureRecognizer]) {
        return [self.longPressGestureRecognizer isEqual:otherGestureRecognizer];
    }
    
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.activeTouch) {
        return NO;
    }
    self.recentTouch = touch;
    return YES;
}

#pragma mark - Key-Value Observing methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kACCReorderableForCollectionViewKeyPath]) {
        if (self.collectionView != nil) {
            [self setupCollectionView];
        } else {
            [self invalidatesScrollTimer];
            [self tearDownCollectionView];
        }
    }
}

#pragma mark - Notifications

- (void)handleApplicationWillResignActive:(NSNotification *)notification
{
    self.panGestureRecognizer.enabled = YES;
}

@end
