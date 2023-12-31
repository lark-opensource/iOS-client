//
//  BDXLynxScrollView.m
//  BDXElement
//
//  Created by li keliang on 2020/3/9.
//

#import "BDXLynxScrollView.h"
#import <Lynx/LynxView.h>
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxLayoutStyle.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import "BDXLynxImpressionView.h"
#import "LynxUI+BDXLynx.h"
#import "BDXLynxBounceView.h"
#import <Lynx/LynxView+Bridge.h>
#import <objc/runtime.h>

@interface UIScrollView(Impression)<BDXLynxImpressionParentView>

@end

@implementation UIScrollView(Impression)

- (void)setBdx_shouldManualExposure:(BOOL)bdx_shouldManualExposure
{
    objc_setAssociatedObject(self, @selector(bdx_shouldManualExposure), @(bdx_shouldManualExposure), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdx_shouldManualExposure
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

@end

@interface LynxUIScroller(X) <UIScrollViewDelegate>

@end

@interface BDXLynxScrollView()

@property (nonatomic, assign) CGFloat sensitivity;
@property (nonatomic, assign) CGPoint lastScrollPoint;
@property (nonatomic, assign) HoverPosition hoverPosition;
@property (nonatomic) BOOL enableDefaultBounceView;

@end

@implementation BDXLynxScrollView {
  BOOL _forceImpression;
}

static Class<BDXLynxScrollViewUIDelegate> kUIDelegate = nil;
+ (Class<BDXLynxScrollViewUIDelegate>)BDXUIDelegate
{
    return kUIDelegate;
}

+ (void)setBDXUIDelegate:(Class<BDXLynxScrollViewUIDelegate>)UIDelegate
{
    kUIDelegate = UIDelegate;
}

#pragma mark - LynxPropsProcessor

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-scroll-view")
#else
LYNX_REGISTER_UI("x-scroll-view")
#endif

LYNX_PROP_SETTER("scroll-to-index", scrollToIndex, NSInteger)
{
    [self scrollToIndex:value];
}

LYNX_PROP_SETTER("scroll-to-id", scrollToID, NSString *)
{
    if ([self view].subviews.count == 0) {
        return;
    }
    
    LynxView *rootView = (LynxView *)self.context.rootView;
    if ([rootView isKindOfClass:LynxView.class]) {
        UIView *indexView = [rootView viewWithName:value];
        [self scrollToSubview:indexView];
    }
}

LYNX_PROP_SETTER("scroll-to-position", postion, NSString *)
{
    if ([value isEqualToString:@"center"]) {
        self.hoverPosition = HoverPositionCenter;
    }
}

LYNX_PROP_SETTER("page-enable", pageEnable, BOOL)
{
    self.view.pagingEnabled = value;
}

LYNX_PROP_SETTER("bounce", bounce, BOOL)
{
    if (value) {
        [self view].alwaysBounceHorizontal = value;
    }
    [self.bounceUIArray enumerateObjectsUsingBlock:^(LynxBounceView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.view.hidden = !value;
    }];
}

LYNX_PROP_SETTER("overflow-text", overflowText, NSString *)
{
    [self.bounceUIArray enumerateObjectsUsingBlock:^(LynxBounceView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj respondsToSelector:@selector(bdx_updateOverflowText:)]){
            [(UIView <BDXLynxScrollViewBounceView> *)obj.view bdx_updateOverflowText:value];
        }
    }];
}

LYNX_PROP_SETTER("layout-direction", layoutDirection, NSString *)
{
    if ([value isEqualToString:@"rtl"]) {
        [self setScrollLeft:1e+6 requestReset:NO];
    } else {
        [self setScrollLeft:0 requestReset:NO];
    }
}

LYNX_PROP_SETTER("enable-default-bounce-view", disableDefaultBounceView, BOOL)
{
    self.enableDefaultBounceView = value;
    if(!value && self.bounceUIArray.count > 0){
        [self.bounceUIArray enumerateObjectsUsingBlock:^(LynxBounceView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.view removeFromSuperview];
        }];
        [self.bounceUIArray removeAllObjects];
    }
}

LYNX_UI_METHOD(scrollToIndex)
{
    NSNumber *index = params[@"index"];
    if ([index isKindOfClass:NSNumber.class]) {
        BOOL succeeded = [self scrollToIndex:index.integerValue];
        !callback ?: callback(succeeded ? kUIMethodSuccess : kUIMethodParamInvalid, nil);
    } else {
        !callback ?: callback(kUIMethodParamInvalid, nil);
    }
}

- (BOOL)scrollToIndex:(NSInteger)index
{
    if ([self view].subviews.count == 0 || index < 0) {
        return NO;
    }
    
    UIView *indexView = [[self view].subviews objectAtIndex:MIN(MAX(0, index), [self view].subviews.count - 1)];
    if (indexView) {
        [self scrollToSubview:indexView];
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - Override

- (UIView *)createView
{
    UIScrollView* scrollView = [super createView];
    scrollView.scrollsToTop = NO;
    scrollView.bdx_shouldManualExposure = YES;
    scrollView.delegate = self;
    
    self.sensitivity = 4.f;
    self.lastScrollPoint = CGPointMake(INFINITY, INFINITY);
    self.hoverPosition = HoverPositionLeft;
    if ([self.class.BDXUIDelegate respondsToSelector:@selector(BDXLynxScrollViewBounceView:)]) {
        UIView* bounceView = [self.class.BDXUIDelegate BDXLynxScrollViewBounceView:self];
        bounceView.hidden = YES;
        LynxBounceView* bounceUI = [[BDXLynxBounceView alloc] initWithView:bounceView];
        [self.bounceUIArray addObject:bounceUI];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lynxImpressionWillManualExposureNotification:) name:BDXLynxImpressionWillManualExposureNotification object:nil];
      
    _forceImpression = NO;  
    return scrollView;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)layoutDidFinished
{
    [super layoutDidFinished];
    self.lastScrollPoint = CGPointMake(INFINITY, INFINITY);

  [self triggerSubviewsImpression];
}

#pragma mark - Actions

- (void)scrollToSubview:(UIView *)subview
{
    switch (self.hoverPosition) {
        case HoverPositionLeft: {
            CGFloat scrollX = CGRectGetMinX(subview.frame);
            CGFloat scrollY = CGRectGetMinY(subview.frame);
            if (self.view.contentSize.width > CGRectGetWidth(self.view.frame) || self.view.contentSize.height > CGRectGetHeight(self.view.frame)) {
              scrollX = MIN(self.view.contentSize.width - CGRectGetWidth(self.view.frame), CGRectGetMinX(subview.frame));
              scrollY = MIN(self.view.contentSize.height - CGRectGetHeight(self.view.frame), CGRectGetMinY(subview.frame));
              [self.view setContentOffset:CGPointMake(scrollX, scrollY) animated:YES];
            }
            break;
        }
        case HoverPositionCenter: {
            CGFloat scrollX = MIN(self.view.contentSize.width - CGRectGetWidth(self.view.frame), CGRectGetMinX(subview.frame) - CGRectGetWidth(self.view.frame)/2 + CGRectGetWidth(subview.frame)/2);
            scrollX = MAX(0,scrollX);
            CGFloat scrollY = MIN(self.view.contentSize.height - CGRectGetHeight(self.view.frame)/2, CGRectGetMinY(subview.frame));
            [self.view setContentOffset:CGPointMake(scrollX, scrollY) animated:YES];
            break;
        }
        default: {
            CGFloat scrollX = MIN(self.view.contentSize.width - CGRectGetWidth(self.view.frame), CGRectGetMinX(subview.frame));
            CGFloat scrollY = MIN(self.view.contentSize.height - CGRectGetHeight(self.view.frame), CGRectGetMinY(subview.frame));
            [self.view setContentOffset:CGPointMake(scrollX, scrollY) animated:NO];
            break;
        }
    }
}

- (void)triggerSubviewsExit
{
    self.lastScrollPoint = CGPointMake(INFINITY, INFINITY);
    [self.view.subviews enumerateObjectsUsingBlock:^(__kindof BDXLynxInnerImpressionView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:BDXLynxInnerImpressionView.class]) {
            return ;
        }
        
        [obj exit];
    }];
}

- (void)triggerSubviewsImpression {
    // When _forceImpression is True, check if the rootView is on the screen.
    // When _forceImpression is False, check if the self (aka. the current scrollView) is on the screen.
  
    CGRect objRect = CGRectZero;
    if (_forceImpression) {
      objRect = [self.context.rootView convertRect:self.context.rootView.bounds toView:nil];
    } else {
      objRect = [self.view convertRect:self.view.bounds toView:nil];
    }
    
    CGRect intersectionRect = CGRectIntersection(self.view.window.bounds, objRect);

    if ((intersectionRect.size.height * intersectionRect.size.width == 0
        || self.view.hidden) && !_forceImpression) {
        return;
    }

    CGPoint contentOffset = self.view.contentOffset;

    if (fabs(self.lastScrollPoint.x - contentOffset.x) > self.sensitivity || fabs(self.lastScrollPoint.y - contentOffset.y) > self.sensitivity) {
        self.lastScrollPoint = self.view.contentOffset;

        // 进行递归检查，避免多个 x-scroll-view 嵌套的时候，
        // 某个外层 scroll-view 滚动的时候 x-impression-view 无法 impression
        [self.children enumerateObjectsUsingBlock:^(LynxUI * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:BDXLynxScrollView.class]) {
              [(BDXLynxScrollView*)obj triggerSubviewsImpression];
            }
        }];

        [self.view.subviews enumerateObjectsUsingBlock:^(__kindof BDXLynxInnerImpressionView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

            if (![obj isKindOfClass:BDXLynxInnerImpressionView.class]) {
                return ;
            }
            
            CGRect objRect = [self.view convertRect:obj.frame fromView:self.view];
            CGRect intersectionRect = CGRectIntersection(self.view.bounds, objRect);
            
            CGFloat intersectionArea = intersectionRect.size.height * intersectionRect.size.width;
            if (intersectionArea == 0) {
                [obj exit];
            } else {
                CGFloat impressionArea = CGRectGetHeight(obj.bounds) * CGRectGetWidth(obj.bounds) * obj.impressionPercent;
                if (intersectionArea >= impressionArea) {
                    [obj impression];
                } else {
                    [obj exit];
                }
            }
        }];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([LynxUIScroller instancesRespondToSelector:_cmd]) {
        [super scrollViewDidScroll:scrollView];
    }
    
    [self triggerSubviewsImpression];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([LynxUIScroller instancesRespondToSelector:_cmd]) {
        [super scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }

    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"dragend" targetSign:[self sign] detail:@{
        @"scrollLeft": @(self.view.contentOffset.x),
        @"scrollTop": @(self.view.contentOffset.y),
        @"scrollWidth": @(self.view.contentSize.width),
        @"scrollHeight": @(self.view.contentSize.height),
    }];
    [self.context.eventEmitter sendCustomEvent:event];
}

#pragma mark -

- (void)lynxImpressionWillManualExposureNotification:(NSNotification *)noti
{
    if (![self.context.rootView isKindOfClass:LynxView.class]) {
        return;
    }
    
    NSString *lynxViewId = ((LynxView *)self.context.rootView).containerID;
    if (![noti.userInfo[BDXLynxImpressionLynxViewIDNotificationKey] isEqualToString:lynxViewId]) {
        return;
    }
    
    if ([noti.userInfo[BDXLynxImpressionStatusNotificationKey] isEqualToString:@"show"]) {
      _forceImpression = [noti.userInfo[BDXLynxImpressionForceImpressionBoolKey] boolValue];
      [self triggerSubviewsImpression];
    } else if ([noti.userInfo[BDXLynxImpressionStatusNotificationKey] isEqualToString:@"hide"]) {
        [self triggerSubviewsExit];
    }
}

@end
