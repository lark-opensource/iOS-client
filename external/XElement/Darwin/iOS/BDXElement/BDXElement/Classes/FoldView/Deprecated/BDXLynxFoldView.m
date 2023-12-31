//
//  BDXLynxFoldView.m
//  BDXElement
//
//  Created by AKing on 2020/9/24.
//

#import "BDXLynxFoldView.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxView.h>
#import <Lynx/LynxUnitUtils.h>
#import "BDXLynxFoldViewItem.h"
#import "BDXLynxPageView.h"
#import "LynxOLEContainerScrollView.h"
#import "BDXLynxFoldViewBar.h"
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <math.h>

@interface BDXFoldView () <UIScrollViewDelegate>

@property (nonatomic, strong) NSArray<LynxUI *> *datas;

@property (nonatomic, strong) LynxOLEContainerScrollView *oleScrollView;

- (void)setupUI;

@end

@implementation BDXFoldView

- (void)setDatas:(NSArray<LynxUI *> *)datas {
    _datas = datas;
}

- (void)setupUI {
    self.oleScrollView = [LynxOLEContainerScrollView new];
    self.oleScrollView.frame = self.frame;
    self.oleScrollView.showsVerticalScrollIndicator = false;
    self.oleScrollView.delegate = self;
    if (@available(iOS 11.0, *)) {
        self.oleScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        // Fallback on earlier versions
    }
    [self addSubview:self.oleScrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.oleScrollView oleScrollViewWillBeginDragging: nil];
}

@end


@interface BDXLynxFoldView () <BDXPageViewProtocol, OLEContainerScrollViewScrollingOffset>

@property(nonatomic, strong, nonnull) NSMutableArray<LynxUI *> *foldItems;
@property (nonatomic, assign) BOOL hasDataChanged;
@property (nonatomic, strong) BDXLynxFoldViewItem *headerView;

@property (nonatomic, strong) BDXLynxPageView *pageView;

@property (nonatomic, strong) BDXLynxFoldViewBar *barView;

@property (nonatomic, strong) NSMutableArray<LynxUI *> *otherViews;

@property (nonatomic, assign) BOOL hasReported1;

@property (nonatomic, assign) BOOL allowVerticalBounce;
// Notify the granularity of the front-end offset, such as 0.01, initialized to 2.0 does not consider the granularity
@property (nonatomic, assign) CGFloat granularity;
// Save the header offset percent of the previous notification
@property (nonatomic, assign) CGFloat preHeaderOffsetPercent;

@end

@implementation BDXLynxFoldView

- (instancetype)init {
    self = [super init];
    if (self) {
        _foldItems = [[NSMutableArray alloc] init];
        _otherViews = [[NSMutableArray alloc] init];
        _granularity = 2.0;
        _preHeaderOffsetPercent = 0.0;
    }
    return self;
}

- (UIView *)createView {
    BDXFoldView *view = [[BDXFoldView alloc] init];
    [view setupUI];
    return view;
}

- (void)insertChild:(LynxUI *)child atIndex:(NSInteger)index {
    [super didInsertChild:child atIndex:index];
    [_foldItems insertObject:child atIndex:index];
    _hasDataChanged = YES;
    if ([child isKindOfClass:[BDXLynxFoldViewItem class]]) {
        self.headerView = (BDXLynxFoldViewItem *)child;
    } else if ([child isKindOfClass:[BDXLynxPageView class]]) {
        self.pageView = (BDXLynxPageView *)child;
        BDXLynxPageView *page = (BDXLynxPageView *)child;
        page.view.viewDelegate = self;
    } else if ([child isKindOfClass:[BDXLynxFoldViewBar class]]) {
        self.barView = (BDXLynxFoldViewBar *)child;
    } else {
        [_otherViews addObject:child];
    }
}

- (void)removeChild:(id)child atIndex:(NSInteger)index {
    [super removeChild:child atIndex:index];
    [_foldItems removeObjectAtIndex:index];
    [[self view] setDatas:_foldItems];
    _hasDataChanged = YES;
    if ([child isKindOfClass:[BDXLynxFoldViewItem class]]) {
        self.headerView = nil;
    } else if ([child isKindOfClass:[BDXLynxPageView class]]) {
        self.pageView = nil;
    } else if ([child isKindOfClass:[BDXLynxFoldViewBar class]]) {
        self.barView = nil;
    } else {
        [_otherViews removeObject:child];
    }
}

- (void)layoutDidFinished {
    CGSize size = self.view.frame.size;
    [self view].oleScrollView.frame = CGRectMake(0, 0, size.width, size.height);
    if(self.barView != nil){
        [self view].oleScrollView.endTopOffset = self.barView.view.frame.size.height;
    } else {
        [self view].oleScrollView.endTopOffset = 0;
    }
    [self view].oleScrollView.offsetDelegate = self;
    if (_hasDataChanged) {
        [[self view] setDatas:_foldItems];
        _hasDataChanged = NO;
        [[self view] addSubview: self.barView.view];
        [[self view].oleScrollView.contentView addSubview: self.headerView.view];
        [[self view].oleScrollView.contentView addSubview: self.pageView.view];
    }
}

- (void)itemSizeDidChange:(UIView *)view {
    [[self view].oleScrollView shouldLayout];
}

- (void)didSelectPage:(LynxUI *)page {
    [[self view].oleScrollView updateTabBarView: self.pageView.view];
    
    CGFloat barHeight = self.barView.view == nil? 0: self.barView.view.frame.size.height;
    CGFloat headerHeight = self.headerView.view.frame.size.height;
    CGFloat deltaHeight = headerHeight - barHeight;
    if([self view].oleScrollView.contentOffset.y < 0) {
        [self setFoldExpanded:YES];
    } else if ([self view].oleScrollView.contentOffset.y > deltaHeight) {
        [self setFoldExpanded:NO];
    } else {
        
    }
}

- (id<LynxEventTarget>)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.context.enableEventRefactor) {
        LynxUI *hit = (LynxUI *)[super hitTest:point withEvent:event];
        return hit;
    }
    
    CGFloat safeTop = 0;

    CGFloat pOffsetY;
    if(self.barView != nil && self.barView.frame.origin.y <= point.y && point.y <= self.barView.frame.origin.y+self.barView.frame.size.height){
        pOffsetY = 0;
    } else {
        pOffsetY = fmin(self.headerView.view.frame.size.height, [self view].oleScrollView.contentOffset.y + (self.barView == nil? 0: self.barView.view.frame.size.height)) - safeTop;
    }

    point = CGPointMake(point.x, point.y + pOffsetY);
    LynxUI *hit = (LynxUI *)[super hitTest:point withEvent:event];
    return hit;
}

#pragma mark - OLEContainerScrollViewScrollingOffset
- (void)whenScrollingWtih:(CGFloat)yOffset {
    CGFloat barHeight = self.barView.view == nil? 0: self.barView.view.frame.size.height;
    CGFloat headerHeight = self.headerView.view.frame.size.height;
    CGFloat deltaHeight = headerHeight - barHeight;
    if(deltaHeight <= 0) return;
    CGFloat percent = yOffset / deltaHeight;
    if(percent < 1) { _hasReported1 = NO; }
    if(percent >= 1) { percent = 1; }
    if(!_hasReported1){
        if(_granularity > 1){
            // No control granularity on the front end
            [self headerOffsetting:@{@"offset":@(percent)}];
        }else{
            if(_preHeaderOffsetPercent<percent){
                // Current decline
                while(true){
                    _preHeaderOffsetPercent += _granularity;
                    if(_preHeaderOffsetPercent>=percent){
                        [self headerOffsetting:@{@"offset":@(percent)}];
                        break;
                    }else{
                        [self headerOffsetting:@{@"offset":@(_preHeaderOffsetPercent)}];
                    }
                }
            }else{
                // Currently sliding up
                while(true){
                    _preHeaderOffsetPercent -= _granularity;
                    if(_preHeaderOffsetPercent<=percent){
                        [self headerOffsetting:@{@"offset":@(percent)}];
                        break;
                    }else{
                        [self headerOffsetting:@{@"offset":@(_preHeaderOffsetPercent)}];
                    }
                }
            }
        }
        if(percent >= 1) { _hasReported1 = YES; }
    }
    _preHeaderOffsetPercent = percent;
}


#pragma mark -

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-foldview")
#else
LYNX_REGISTER_UI("x-foldview")
#endif

- (void)headerOffsetting:(NSDictionary *)info {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:@"offset" targetSign:[self sign] detail:info];
    [self.context.eventEmitter sendCustomEvent:event];
}

LYNX_UI_METHOD(setFoldExpanded) {
    CGFloat expanded = NO;
    BOOL success = NO;
    NSString *msg;
    if ([[params allKeys] containsObject:@"expanded"]) {
        expanded = [[params objectForKey:@"expanded"] floatValue];
        if(expanded < 0) expanded = 0;
        if(expanded > 1) expanded = 1;
        CGFloat barHeight = self.barView.view == nil? 0: self.barView.view.frame.size.height;
        CGFloat headerHeight = [self headerView].view.frame.size.height;
        CGFloat deltaHeight = headerHeight - barHeight;
        if([self view].oleScrollView.contentOffset.y > deltaHeight){
            success = NO;
            msg = @"header must be folded";
        }else{
            [self view].oleScrollView.contentOffset = CGPointMake(0, deltaHeight * (1.0 - expanded));
            success = YES;
            msg = @"";
        }
    } else {
        success = NO;
        msg = @"no expanded key";
    }
    callback(
      kUIMethodSuccess, @{
          @"success": @(success),
          @"msg": msg,
      });
}

-(void)setFoldExpanded :(BOOL)expanded {
    if(expanded){
        [self view].oleScrollView.contentOffset = CGPointMake(0, 0);
    } else {
        CGFloat barHeight = self.barView.view == nil? 0: self.barView.view.frame.size.height;
        CGFloat headerHeight = [self headerView].view.frame.size.height;
        CGFloat deltaHeight = headerHeight - barHeight;
        [self view].oleScrollView.contentOffset = CGPointMake(0, deltaHeight);
    }
}

LYNX_PROP_SETTER("allow-vertical-bounce", allowVerticalBounce, BOOL) {
    _allowVerticalBounce = value;
    self.view.oleScrollView.bounces = value;
    self.view.oleScrollView.alwaysBounceVertical = value;
}

LYNX_PROP_SETTER("granularity", granularity, CGFloat) {
    _granularity = value;
}

@end
