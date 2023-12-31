//
//  BDPAppPage+BDPAppearance.m
//  Timor
//
//  Created by liuxiangxin on 2019/4/15.
//

#import "BDPAppPage+BDPScroll.h"
#import <OPFoundation/UIColor+BDPExtension.h>
#import "BDPPageConfig.h"
#import <objc/runtime.h>
#import <OPSDK/OPSDK-Swift.h>

static void *BDPAppPageScrollObserverContext = &BDPAppPageScrollObserverContext;

@interface BDPAppPageScrollObserver : NSObject

@property (nonatomic, weak) BDPAppPage *page;
@property (nonatomic, strong) UIColor *backgroundColorTop;
@property (nonatomic, strong) UIColor *backgroundColorBottom;
@property (nonatomic, strong) UIColor *pageBackgroundColor;

@end

@implementation BDPAppPageScrollObserver

- (instancetype)initWithPage:(BDPAppPage *)page
{
    self = [super init];
    if (self) {
        _page = page;
        _pageBackgroundColor = page.scrollView.backgroundColor;
        [page.scrollView addObserver:self
                          forKeyPath:NSStringFromSelector(@selector(contentOffset))
                             options:(NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew)
                             context:BDPAppPageScrollObserverContext];
    }
    return self;
}

- (void)stopObserve
{
    [_page.scrollView removeObserver:self
                          forKeyPath:NSStringFromSelector(@selector(contentOffset))
                             context:BDPAppPageScrollObserverContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    BOOL canHandle = NO;
    if (context == BDPAppPageScrollObserverContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentOffset))]) {
            canHandle = YES;
            
            [self pageContentOffsetChanged:change];
        }
    }
    
    if (!canHandle) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

- (void)pageContentOffsetChanged:(NSDictionary *)change
{
    if (self.page.bap_pageConfig.window.disableScroll.boolValue) {
        return;
    }
    
    UIScrollView *scrollView = self.page.scrollView;
    CGPoint contentOffset = [[change valueForKey:NSKeyValueChangeNewKey] CGPointValue];
    BOOL isReachedTop = contentOffset.y <= 0;
    BOOL isReachedBottom = contentOffset.y >= scrollView.contentSize.height - CGRectGetHeight(scrollView.bounds);
    if (isReachedTop) {
        [self pageDidReachedTop];
    } else if (isReachedBottom) {
        [self pageDidReachedBottom];
    } else {
        scrollView.backgroundColor = self.pageBackgroundColor;
    }
}

- (void)pageDidReachedTop
{
    UIScrollView *scrollView = self.page.scrollView;
    scrollView.backgroundColor = self.backgroundColorTop;
}

- (void)pageDidReachedBottom
{
    UIScrollView *scrollView = self.page.scrollView;
    scrollView.backgroundColor = self.backgroundColorBottom;
}

- (UIColor *)backgroundColorTop
{
    if (!_backgroundColorTop) {
        _backgroundColorTop = self.page.bap_pageConfig.window.themeBackgroundColorTop;
    }
    
    return _backgroundColorTop;
}

- (UIColor *)backgroundColorBottom
{
    if (!_backgroundColorBottom) {
        _backgroundColorBottom = self.page.bap_pageConfig.window.themeBackgroundColorBottom;
    }
    
    return _backgroundColorBottom;
}


@end

@implementation BDPAppPage (BDPScroll)

- (void)bdp_setupPageObserver
{
    [self bdp_pageObserver];
}

- (void)bdp_removePageObserver
{
    BDPAppPageScrollObserver *observer = [self bdp_pageObserver];
    [observer stopObserve];
    objc_setAssociatedObject(self, @selector(bdp_pageObserver), nil, OBJC_ASSOCIATION_RETAIN);
}

- (BDPAppPageScrollObserver *)bdp_pageObserver
{
    BDPAppPageScrollObserver *observer = objc_getAssociatedObject(self, @selector(bdp_pageObserver));
    if (!observer) {
        observer = [[BDPAppPageScrollObserver alloc] initWithPage:(BDPAppPage *)self];
        objc_setAssociatedObject(self, @selector(bdp_pageObserver), observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return observer;
}

@end
