/*
 OLEContainerScrollView
 
 Copyright (c) 2014 Ole Begemann.
 https://github.com/ole/OLEContainerScrollView
 */

#import <QuartzCore/QuartzCore.h>

#import "LynxOLEContainerScrollView.h"
#import "LynxOLEContainerScrollView_Private.h"
#import "LynxOLEContainerScrollViewScrollingOffset.h"
#import "LynxOLEContainerScrollView+Swizzling.h"

@interface LynxOLEContainerScrollView ()

@property (nonatomic, readonly) NSMutableArray *subviewsInLayoutOrder;
@property (nonatomic, assign) BOOL oleEffectingSub;
@property (nonatomic, assign) CGFloat diffValueToEndTop;
@end


@implementation LynxOLEContainerScrollView

- (void)oleScrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (self.currentSubScrollView != nil && self.currentSubScrollView.scrollEnabled == NO) {
        if ([self.currentSubScrollView.delegate respondsToSelector:@selector(scrollViewWillBeginDragging:)]) {
            [self.currentSubScrollView.delegate scrollViewWillBeginDragging:self.currentSubScrollView];
        }
    }
}

+ (void)initialize
{
    // +initialize can be called multiple times if subclasses don't implement it.
    // Protect against multiple calls
    if (self == [LynxOLEContainerScrollView self]) {
        swizzleUICollectionViewLayoutFinalizeCollectionViewUpdates();
        swizzleUITableView();
    }
}

- (void)dealloc
{
    // Removing the subviews will unregister KVO observers
    for (UIView *subview in self.contentView.subviews) {
        [subview removeFromSuperview];
    }
    if(_currentSubScrollView != nil){
        [_currentSubScrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:KVOContext];
        _currentSubScrollView = nil;
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInitForOLEContainerScrollView];
        _endTopOffset = 0;
        _oleEffectingSub = YES;
//        [self addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionOld context:KVOContext];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInitForOLEContainerScrollView];
}

- (void)commonInitForOLEContainerScrollView
{
    _contentView = [[LynxOLEContainerScrollViewScrollingOffset alloc] initWithFrame:CGRectZero];
    [self addSubview:_contentView];
    _subviewsInLayoutOrder = [NSMutableArray arrayWithCapacity:4];
    _spacing = 0.0;
    _ignoreHiddenSubviews = YES;
}

- (void)setSpacing:(CGFloat)spacing {
    _spacing = spacing;
    [self setNeedsLayout];
}

- (void)setIgnoreHiddenSubviews:(BOOL)newValue {
    _ignoreHiddenSubviews = newValue;
    [self setNeedsLayout];
}

-(void)updateTabBarView:(UIView *)subview {
    NSParameterAssert(subview != nil);
    NSUInteger ix = [self.subviewsInLayoutOrder indexOfObjectIdenticalTo:subview];
    if (ix != NSNotFound) {
        if ([subview respondsToSelector:@selector(tabContentViews)]) {
            NSArray<UIView *> *tabBarViews = [subview performSelector:@selector(tabContentViews)];
            if (tabBarViews.count > 0) {
                for (UIView *tempView in tabBarViews) {
                    if ([tempView isKindOfClass:[UIScrollView class]]) {
                        UIScrollView *scrollView = (UIScrollView *)tempView;
                        scrollView.scrollEnabled = NO;
                        
                        _oleEffectingSub = YES;
                        scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x, 0);
                        _oleEffectingSub = NO;
                    }
                }
            }
        }
    }
    [self shouldLayout];
}

- (void)shouldLayout {
    [self setNeedsLayout];
}

#pragma mark - Adding and removing subviews

- (void)didAddSubviewToContainer:(UIView *)subview
{
    NSParameterAssert(subview != nil);

    NSUInteger ix = [self.subviewsInLayoutOrder indexOfObjectIdenticalTo:subview];
    if (ix != NSNotFound) {
        [self.subviewsInLayoutOrder removeObjectAtIndex:ix];
        [self.subviewsInLayoutOrder addObject:subview];
        [self setNeedsLayout];
        return;
    }

    subview.autoresizingMask = UIViewAutoresizingNone;

    [self.subviewsInLayoutOrder addObject:subview];

    if ([subview isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)subview;
        scrollView.scrollEnabled = NO;
        [scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionOld context:KVOContext];
    } else if ([self hasScrollView:subview]) {
        UIScrollView *scrollView = [subview performSelector:@selector(scrollView)];
        scrollView.scrollEnabled = NO;
        [scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionOld context:KVOContext];
    }  else {
        [subview addObserver:self forKeyPath:NSStringFromSelector(@selector(frame)) options:NSKeyValueObservingOptionOld context:KVOContext];
        [subview addObserver:self forKeyPath:NSStringFromSelector(@selector(bounds)) options:NSKeyValueObservingOptionOld context:KVOContext];
    }
    
    [self setNeedsLayout];
}

- (void)willRemoveSubviewFromContainer:(UIView *)subview
{
    NSParameterAssert(subview != nil);
    if ([subview isKindOfClass:[UIScrollView class]]) {
        [subview removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:KVOContext];
    } else if ([self hasScrollView:subview]) {
        UIScrollView *scrollView = [subview performSelector:@selector(scrollView)];
        [scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:KVOContext];
    }  else {
        [subview removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame)) context:KVOContext];
        [subview removeObserver:self forKeyPath:NSStringFromSelector(@selector(bounds)) context:KVOContext];
    }
    [self.subviewsInLayoutOrder removeObject:subview];
    [self setNeedsLayout];
}

#pragma mark - KVO

static void *KVOContext = &KVOContext;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == KVOContext) {
        // Initiate a layout recalculation only when a subviewʼs frame or contentSize has changed
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
            UIScrollView *scrollView = object;
            CGSize oldContentSize = [change[NSKeyValueChangeOldKey] CGSizeValue];
            CGSize newContentSize = scrollView.contentSize;
            if (!CGSizeEqualToSize(newContentSize, oldContentSize)) {
                [self setNeedsLayout];
                [self layoutIfNeeded];
            }
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(frame))] ||
                   [keyPath isEqualToString:NSStringFromSelector(@selector(bounds))]) {
            UIView *subview = object;
            CGRect oldFrame = [change[NSKeyValueChangeOldKey] CGRectValue];
            CGRect newFrame = subview.frame;
            if (!CGRectEqualToRect(newFrame, oldFrame)) {
                [self setNeedsLayout];
                [self layoutIfNeeded];
            }
        }  else if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
            if(object==self){
                if(_offsetDelegate != nil)
                {
                    if([(NSObject *)_offsetDelegate respondsToSelector:@selector(whenScrollingWtih:)])
                    {
                        [_offsetDelegate whenScrollingWtih:self.contentOffset.y];
                    }
                }
            }else {
                if(!_oleEffectingSub && _currentSubScrollView!=nil) {
                    if(fabs(_currentSubScrollView.contentOffset.y)<0.001) {
                    }else{
                        self.contentOffset = CGPointMake(self.contentOffset.x, _currentSubScrollView.contentOffset.y + _diffValueToEndTop);
                    }
                }
            }
         }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)setCurrentSubScrollView:(UIScrollView *)currentSubScrollView {
    if(_currentSubScrollView == currentSubScrollView) return;
    if(_currentSubScrollView != nil){
        [_currentSubScrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) context:KVOContext];
    }
    _currentSubScrollView = currentSubScrollView;
    _currentSubScrollView.scrollEnabled = NO;
    if(_currentSubScrollView != nil){
        [_currentSubScrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentOffset)) options:NSKeyValueObservingOptionOld context:KVOContext];
    }
}

- (void)setContentOffset:(CGPoint)contentOffset {
    [super setContentOffset:contentOffset];
    if(_offsetDelegate != nil)
    {
        if([(NSObject *)_offsetDelegate respondsToSelector:@selector(whenScrollingWtih:)])
        {
            [_offsetDelegate whenScrollingWtih:self.contentOffset.y];
        }
    }
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    // Translate the container view's content offset to contentView bounds.
    // This keeps the contentView always centered on the visible portion of the container view's
    // full content size, and avoids the need to make the contentView large enough to fit the
    // container view's full content size.
    self.contentView.frame = self.bounds;
    self.contentView.bounds = (CGRect){ self.contentOffset, self.contentView.bounds.size };
    
    // The logical vertical offset where the current subview (while iterating over all subviews)
    // must be positioned. Subviews are positioned below each other, in the order they were added
    // to the container. For scroll views, we reserve their entire contentSize.height as vertical
    // space. For non-scroll views, we reserve their current frame.size.height as vertical space.
    CGFloat yOffsetOfCurrentSubview = 0.0;
    
    for (int index = 0; index < self.subviewsInLayoutOrder.count; index++)
    {
        
        UIView *subview = self.subviewsInLayoutOrder[index];
        UIView *tabSelectView = nil;
        
        // Make the height hidden subviews zero in order to behave like UIStackView.
        if (self.ignoreHiddenSubviews && subview.hidden) {
            CGRect frame = subview.frame;
            frame.origin.y = yOffsetOfCurrentSubview;
            frame.origin.x = 0;
            frame.size.width = self.contentView.bounds.size.width;
            subview.frame = frame;
            
            // Do not set the height to zero. Just don't add the original height to yOffsetOfCurrentSubview.
            // This is to keep the original height when the view is unhidden.
            continue;
        }
        UIScrollView *scrollView = nil;
        if ([self hasScrollView:subview] ) {
            scrollView = [subview performSelector:@selector(scrollView)];
        }
        if ([subview isKindOfClass:[UIScrollView class]]) {
            scrollView = (UIScrollView *)subview;
        }
        if ([subview respondsToSelector:@selector(tabContentViews)]) {
            NSArray<UIView *> *tabBarViews = [subview performSelector:@selector(tabContentViews)];
            NSInteger index = 0;
            if ([subview respondsToSelector:@selector(selected)]) {
                index = (long)[subview performSelector:@selector(selected)];
            }
            if (index < tabBarViews.count) {
                UIView *tempView = tabBarViews[index];
                if ([tempView isKindOfClass:[UIScrollView class]]) {
                    scrollView = (UIScrollView *)tempView;
                } else {
                    tabSelectView = tempView;
                }
            }
        }
        if (scrollView != nil) {
            self.currentSubScrollView = scrollView;
            
            CGRect frame = subview.frame;
            CGPoint contentOffset = scrollView.contentOffset;
            _diffValueToEndTop = yOffsetOfCurrentSubview-_endTopOffset;
            
            // Translate the logical offset into the sub-scrollview's real content offset and frame size.
            // Methodology:
            
            // (1) As long as the sub-scrollview has not yet reached the top of the screen, set its scroll position
            // to 0.0 and position it just like a normal view. Its content scrolls naturally as the container
            // scroll view scrolls.
            if (self.contentOffset.y < _diffValueToEndTop) {
                // 未吸顶
                contentOffset.y = 0.0;
                frame.origin.y = yOffsetOfCurrentSubview;
            }
            // (2) If the user has scrolled far enough down so that the sub-scrollview reaches the top of the
            // screen, position its frame at 0.0 and start adjusting the sub-scrollview's content offset to
            // scroll its content.
            else {
                // 已吸顶
                contentOffset.y = self.contentOffset.y - yOffsetOfCurrentSubview + _endTopOffset;
                frame.origin.y = self.contentOffset.y + _endTopOffset;
                
            }
            
            // (3) The sub-scrollview's frame should never extend beyond the bottom of the screen, even if its
            // content height is potentially much greater. When the user has scrolled so far that the remaining
            // content height is smaller than the height of the screen, adjust the frame height accordingly.
            frame.size.width = self.contentView.bounds.size.width;
//            CGFloat remainingBoundsHeight = fmax(CGRectGetMaxY(self.bounds) - CGRectGetMinY(frame), 0.0);
//            CGFloat remainingContentHeight = fmax(scrollView.contentSize.height - contentOffset.y, 0.0);
//            frame.size.height = fmin(remainingBoundsHeight, remainingContentHeight);
//            frame.size.width = self.contentView.bounds.size.width;
            subview.frame = frame;
//            CGFloat delt = frame.size.height - (scrollView.frame.origin.y + scrollView.frame.size.height);
//            scrollView.frame = CGRectMake(scrollView.frame.origin.x, scrollView.frame.origin.y, scrollView.frame.size.width, scrollView.frame.size.height + delt);
            _oleEffectingSub = YES;
            
            scrollView.contentOffset = contentOffset;
            
            _oleEffectingSub = NO;
            
            yOffsetOfCurrentSubview += scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom + (frame.size.height - scrollView.frame.size.height);
        } else {
            // Normal views are simply positioned at the current offset
            CGRect frame = subview.frame;
            if (self.contentOffset.y < frame.size.height - _endTopOffset) {
                frame.origin.y = yOffsetOfCurrentSubview;
            } else {
                frame.origin.y = self.contentOffset.y - (frame.size.height - _endTopOffset);
            }
            frame.origin.x = 0;
            frame.size.width = self.contentView.bounds.size.width;
            subview.frame = frame;
            if (tabSelectView != nil) {
                yOffsetOfCurrentSubview += tabSelectView.frame.size.height;
            } else {
                yOffsetOfCurrentSubview += frame.size.height;
            }
        }

        if (index < (self.subviewsInLayoutOrder.count - 1)) {
            yOffsetOfCurrentSubview += self.spacing;
        }
    }
    
    // If our content is shorter than our bounds height, take the contentInset into account to avoid
    // scrolling when it is not needed.
    CGFloat minimumContentHeight = self.bounds.size.height - (self.contentInset.top + self.contentInset.bottom);

    CGPoint initialContentOffset = self.contentOffset;
    self.contentSize = CGSizeMake(self.bounds.size.width, fmax(yOffsetOfCurrentSubview, minimumContentHeight));
    
    // If contentOffset changes after contentSize change, we need to trigger layout update one more time.
    if (!CGPointEqualToPoint(initialContentOffset, self.contentOffset)) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

- (BOOL)hasScrollView:(UIView *)subview {
    if ([subview respondsToSelector:@selector(scrollView)]) {
        if (subview != nil) {
            return true;
        }
    }
    return false;
}

@end
