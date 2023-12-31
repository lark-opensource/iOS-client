//
//  ACCToolBarView.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/27.
//

#import "ACCToolBarView.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCBarItemContainerView.h>

ACCContextId(ACCRecorderToolBarMoreButtonContext)

static NSTimeInterval kACCToolBarViewLabelDismissDuration = 0.3;
static NSTimeInterval kACCToolBarViewLabelShowDuration = 0;

@interface ACCToolBarView ()

@property (nonatomic, assign) BOOL folded;
@property (nonatomic, assign) BOOL labelShowing;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableArray<ACCBarItem *> *itemsArray;
@property (nonatomic, strong) NSMutableArray<ACCToolBarItemView *> *cacheViewsArray;
@property (nonatomic, strong) NSMutableArray *ordersArray;
@property (nonatomic, strong) NSMutableArray *forceInsertArray;
@property (nonatomic, strong) NSMutableArray *redPointArray;
@end

@implementation ACCToolBarView

#pragma mark init

- (instancetype)initWithLayout:(ACCToolBarCommonViewLayout *)layout itemsData:(NSArray<ACCBarItem *> *)items ordersArray:(NSArray *)ordersArray redPointArray:(NSArray *)redPointArray forceInsertArray:(NSArray *)forceInsertArray isEdit:(BOOL)isEdit
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _layout = layout;
        _itemsArray = [NSMutableArray array];
        [items enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // items in edit page have no needShowBlock
            if ((obj.needShowBlock && obj.needShowBlock()) || !obj.needShowBlock) {
                [_itemsArray addObject:obj];
            }
        }];
        _cacheViewsArray = [NSMutableArray array];
        _forceInsertArray = [NSMutableArray arrayWithArray:forceInsertArray];
        _ordersArray = [NSMutableArray arrayWithArray:ordersArray];
        _redPointArray = [NSMutableArray arrayWithArray:redPointArray];

        _folded = YES;
        _labelShowing = YES;
        _isEdit = isEdit;
    }
    return self;
}

- (void)setupUI
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self p_checkAndShowBubble];
    });

    [self p_sortItemsArray];

    self.backgroundColor = [UIColor clearColor];

    // add views
    @weakify(self);
    [self.itemsArray enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        ACCToolBarItemView *barItemView = [self p_createBarItemViewWithItem:obj];
        [self.cacheViewsArray addObject:barItemView];
        [self.scrollStackView.stackView addArrangedSubview:barItemView];
    }];

    // scrollStackView
    [self addSubview:self.scrollStackView];

    // button
    [self addSubview:self.moreButtonView];

    // layout
    [self layoutScrollStackView];
    [self layoutMoreButtonView];
    [self layoutIfNeeded];
}

- (void)resetShrinkState
{
    self.folded = YES;
    [self layoutUIWithFolded:YES];
}

- (void)resetUI
{
    self.folded = YES;
    [self layoutUIWithFolded:YES];
}

- (void)resetFoldStateAndShowLabel
{
    self.folded = YES;
    [self layoutUIWithFolded:YES];
}

- (void)resetFoldState
{
    self.folded = YES;
    [self layoutUIWithFolded:YES];
}

- (ACCToolBarItemView *)p_createBarItemViewWithItem:(ACCBarItem *)item
{
    ACCToolBarItemView *barItemView = [[ACCToolBarItemView alloc] init];
    BOOL needHideRedPoint = ![self.redPointArray containsObject:[NSValue valueWithPointer: item.itemId]];
    ACCToolBarItemViewDirection direction = [self barItemDirection];
    [barItemView configWithItem:item direction:direction hideRedPoint:needHideRedPoint buttonSize:self.layout.itemSize];
    ACCBarItemFunctionType type = item.type;

    // config click Block
    @weakify(self);
    ACCBLOCK_INVOKE(item.barItemViewConfigBlock, barItemView);
    barItemView.itemViewDidClicked = ^(UIButton * _Nonnull sender) {
        @strongify(self);
        [self clickedBarItemType:type];
        ACCBLOCK_INVOKE(self.clickItemBlock, sender);
        ACCBLOCK_INVOKE(item.barItemActionBlock, sender);
    };
    return barItemView;
}

- (ACCToolBarScrollStackView *)scrollStackView
{
    if (!_scrollStackView) {
        ACCToolBarScrollStackView *scrollStackView = [[ACCToolBarScrollStackView alloc] init];
        scrollStackView.stackView.distribution = UIStackViewDistributionEqualSpacing;
        scrollStackView.stackView.spacing = self.layout.itemSpacing;
        scrollStackView.stackView.axis = UILayoutConstraintAxisVertical;
        scrollStackView.stackView.translatesAutoresizingMaskIntoConstraints = NO;
        scrollStackView.backgroundColor = [UIColor clearColor];
        scrollStackView.showsVerticalScrollIndicator = NO;
        scrollStackView.scrollEnabled = NO;
        if (@available(iOS 11.0, *)) {
            scrollStackView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _scrollStackView = scrollStackView;
        
    }
    return  _scrollStackView;
}

- (ACCToolBarItemView *)moreButtonView
{
    if (!_moreButtonView) {
        ACCToolBarItemView *moreButtonView = [[ACCToolBarItemView alloc] init];
        ACCBarItem *configItem = [[ACCBarItem alloc] initWithImageName:@"icon_sidebar_more" title:@"更多" itemId:ACCRecorderToolBarMoreButtonContext];

        [moreButtonView configWithItem:configItem direction:[self barItemDirection] hideRedPoint:![self p_shouldShowMoreButtonRedPoint] buttonSize:self.layout.moreButtonSize];

        [moreButtonView.button addTarget:self action:@selector(onMoreButtonClicked) forControlEvents:UIControlEventTouchUpInside];

        moreButtonView.button.isAccessibilityElement = YES;
        moreButtonView.button.accessibilityTraits = UIAccessibilityTraitButton;
        moreButtonView.button.accessibilityLabel = moreButtonView.title;

        [moreButtonView clearHideRedPointCache];

        _moreButtonView = moreButtonView;
    }

    return _moreButtonView;
}

- (NSArray *)viewsArray
{
    NSArray *array = [NSArray arrayWithArray:self.scrollStackView.stackView.arrangedSubviews];
    return [array copy];
}

- (void)layoutMoreButtonView
{
    if ([self p_shouldShowMoreButton]) {
        self.moreButtonView.hidden = NO;
        ACCMasReMaker(self.moreButtonView, {
            make.top.equalTo(self.scrollStackView.mas_bottom).offset(self.layout.moreButtonSpacing);
        });
    } else {
        self.moreButtonView.hidden = YES;
        ACCMasReMaker(self.moreButtonView, {
            make.top.equalTo(self.scrollStackView.mas_bottom).offset(self.layout.moreButtonSpacing);
            make.right.equalTo(self);
        });
    }
    if (self.folded) {
        self.moreButtonView.title = @"更多";
        self.moreButtonView.button.accessibilityLabel = @"更多";
    } else {
        self.moreButtonView.title = @"关闭";
        self.moreButtonView.button.accessibilityLabel = @"关闭";
    }
}

- (void)layoutScrollStackView
{
    ACCMasUpdate(self.scrollStackView, {
        make.top.equalTo(self);
        make.right.equalTo(self);
        make.height.mas_equalTo([self calculateScrollStackViewFrameHeight]);
        make.width.equalTo(self);
    });
}

- (void)layoutUIWithFolded:(BOOL)folded
{
    CGAffineTransform transfrom = folded ? CGAffineTransformMakeRotation(0) : CGAffineTransformMakeRotation(-M_PI);

    [self layoutScrollStackView];
    [self layoutMoreButtonView];

    @weakify(self);
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        @strongify(self);
        [self layoutIfNeeded];
        [self.scrollStackView layoutIfNeeded];
        self.moreButtonView.button.transform = transfrom;
    } completion:^(BOOL finished) {
        [self p_checkAndShowBubble];
    }];
}

- (BOOL)p_shouldShowMoreButtonRedPoint
{
    BOOL show = NO;
    NSUInteger begin = [self p_numberOfItemsFolded];
    NSUInteger end = [self.viewsArray count];
    for (NSUInteger i = begin; i < end; i++) {
        ACCToolBarItemView *view = self.viewsArray[i];
        if (view.shouldShowRedPoint) {
            show = YES;
            break;
        }
    }
    return show;
}

#pragma mark - sort

- (void)p_sortItemsArray
{
    [self p_sortItemsArrayWithOrders:self.ordersArray];
    [self forceInsertWithBarItemIdsArray:self.forceInsertArray];
}

- (void)p_sortItemsArrayWithOrders:(NSArray *)toolBarSortItemArray
{
    if (toolBarSortItemArray.count > 0) {
        [self.itemsArray sortUsingComparator:^NSComparisonResult(ACCBarItem* _Nonnull obj1, ACCBarItem* _Nonnull obj2) {
            NSComparisonResult result = NSOrderedSame;
            if (([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj1.itemId]] != NSNotFound) && ([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj2.itemId]] != NSNotFound)) {
                NSNumber *index1 = @([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj1.itemId]]);
                NSNumber *index2 = @([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj2.itemId]]);
                result = [index1 compare:index2];
            }
            return result;
        }];
    }
}

- (void)forceInsertWithBarItemIdsArray:(NSArray<NSValue *> *)ids
{
    // insert to the last place
    NSUInteger numFolded = [self p_numberOfItemsFolded];
    NSUInteger index = MAX(numFolded - [ids count], 0);

    [ids enumerateObjectsUsingBlock:^(NSValue * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        void *itemId = [obj pointerValue];
        ACCBarItem *item = [self p_barItemWithItemId:itemId];
        if (item) {
            [self.itemsArray removeObject:item];
            [self.itemsArray insertObject:item atIndex:index];
        }
    }];
}

- (void)p_sortItemViews
{
    // remove all
    NSMutableArray<UIView *> *tmpArray = [NSMutableArray arrayWithArray:self.scrollStackView.stackView.arrangedSubviews];
    [self.scrollStackView.stackView.arrangedSubviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    // order array
    __block NSMutableArray *toolBarSortItemArray = [NSMutableArray array];
    [self.itemsArray enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj != nil) {
            [toolBarSortItemArray addObject: [NSValue valueWithPointer:obj.itemId]];
        }
    }];
    // sort
    [tmpArray sortUsingComparator:^NSComparisonResult(ACCToolBarItemView * _Nonnull obj1, ACCToolBarItemView * _Nonnull obj2) {
        NSComparisonResult result = NSOrderedSame;
        if (([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj1.itemId]] != NSNotFound) && ([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj2.itemId]] != NSNotFound)) {
            NSNumber *index1 = @([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj1.itemId]]);
            NSNumber *index2 = @([toolBarSortItemArray indexOfObject:[NSValue valueWithPointer:obj2.itemId]]);
            result = [index1 compare:index2];
        }
        return result;
    }];
    
    // add all
    [tmpArray enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.scrollStackView.stackView addArrangedSubview:obj];
    }];
}

- (void) p_forceInsertWithItemId:(void *)itemId index:(NSUInteger)index
{
    index = MAX(index, 0);
    ACCBarItem *item = [self p_barItemWithItemId:itemId];
    if (item) {
        [self.itemsArray removeObject:item];
        [self.itemsArray insertObject:item atIndex:index];
    }
}

#pragma mark interaction

- (void)insertItem:(ACCBarItem *)item
{
    if (![self.itemsArray containsObject:item]) {
        [self.itemsArray addObject:item];
    }
    [self p_sortItemsArray]; // sort itemsArray
    ACCToolBarItemView *barItemView = [self p_getViewForbarItem:item];
    [self.cacheViewsArray addObject:barItemView];

    if (!self.labelShowing) {
        [barItemView hideLabelWithDuration:0];
    }
    [self.scrollStackView.stackView addArrangedSubview:barItemView];

    [self p_sortItemViews]; // sort views base on itemsArray

    [self insertRemoveUI];
}

-(void)removeItem:(ACCBarItem *)item
{
    if ([self.itemsArray containsObject:item]) {
        [self.itemsArray removeObject:item];
        ACCToolBarView *barItemView = (ACCToolBarView *)[self viewWithBarItemID:item.itemId];
        [barItemView removeFromSuperview];
        [self insertRemoveUI];
    }
}

- (void)insertRemoveUI
{
    [self layoutScrollStackView];
    [self layoutMoreButtonView];

    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
    }];

    if ([self p_shouldShowMoreButtonRedPoint]) {
        [self.moreButtonView showRedPoint];
    }
}

- (ACCToolBarItemView *)p_getViewForbarItem:(ACCBarItem *)item
{
    __block ACCToolBarItemView *view = nil;
    [self.cacheViewsArray enumerateObjectsUsingBlock:^(ACCToolBarItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.itemId == item.itemId) {
            view = obj;
            *stop = YES;
        }
    }];
    if (view == nil) {
        view = [self p_createBarItemViewWithItem:item];
    }
    return view;
}

- (void) onMoreButtonClicked
{
    self.folded = !self.folded;
    [self layoutUIWithFolded:self.folded];
    ACCBLOCK_INVOKE(self.clickMoreBlock, self.folded);
}

#pragma mark - layout func

- (NSUInteger) numberOfAllItems
{
    return [self.itemsArray count];
}

// whether show the More Button
- (BOOL) p_shouldShowMoreButton
{
    NSAssert(NO, @"Implement this method in subclasses");
    return NO;
}

// number of items on toolbar in folded state
- (NSUInteger) p_numberOfItemsFolded
{
    NSAssert(NO, @"Implement this method in subclasses");
    return 0;
}

// number of items show on toolbar, folded or unfolded
- (NSUInteger)p_numberOfItemsToShow
{
    NSAssert(NO, @"Implement this method in subclasses");
    return 0;
}

// size of the scrollStackView, frame size
- (CGFloat)calculateScrollStackViewFrameHeight
{
    NSArray *array = [self p_itemViewsToShow];
    __block CGFloat height = 0;
    [array enumerateObjectsUsingBlock:^(UIView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        height += obj.frame.size.height;
    }];
    height += self.layout.itemSpacing * ([array count] - 1);
    return height;
}

- (NSArray *)p_itemViewsToShow
{
    NSMutableArray *resultArray = [NSMutableArray array];
    NSIndexSet *indexes = [self indexesOfItemsToshow];

    [self.viewsArray enumerateObjectsUsingBlock:^(ACCToolBarItemView *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([indexes containsIndex:idx]) {
            [resultArray addObject:obj];
            obj.button.isAccessibilityElement = YES;
        } else {
            obj.button.isAccessibilityElement = NO;
        }
    }];
    return resultArray;
}

-(NSIndexSet *)indexesOfItemsToshow
{
    NSUInteger numToShow = [self p_numberOfItemsToShow];
    NSUInteger numFolded = [self p_numberOfItemsFolded];
    NSUInteger numAll = [self numberOfAllItems];

    NSUInteger begin = self.folded ? 0 : numFolded;
    NSUInteger end = self.folded ? numToShow : numAll;

    if (numToShow == numAll) {
        begin = 0;
        end = numAll;
    }
    begin = MIN(begin, end);
    end = MIN(end, [self.viewsArray count]);
    NSRange range = NSMakeRange(begin, end - begin);
    NSIndexSet *indexes = [[NSIndexSet alloc] initWithIndexesInRange:range];
    return indexes;
}
#pragma mark - View

- (id<ACCBarItemCustomView>)viewWithBarItemID:(nonnull void *)itemId
{
    __block ACCToolBarItemView *barItemView = nil;
    [self.cacheViewsArray enumerateObjectsUsingBlock:^(__kindof ACCToolBarItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.itemId == itemId) {
            barItemView = obj;
            *stop = YES;
        }
    }];
    return barItemView;
}

# pragma mark - View style
- (ACCToolBarItemViewDirection) barItemDirection
{
    NSAssert(NO, @"Implement this method in subclasses");
    return ACCToolBarItemViewDirectionHorizontal;
}

- (void)hideAllLabelWithSeconds:(double)seconds
{
    NSAssert(NO, @"Implement this method in subclasses");
}

- (void)hideAllLabel
{
    [self.viewsArray enumerateObjectsUsingBlock:^(ACCToolBarItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj hideLabelWithDuration:kACCToolBarViewLabelDismissDuration];
    }];
    [self.moreButtonView hideLabelWithDuration:kACCToolBarViewLabelDismissDuration];
    self.labelShowing = NO;
}

- (void)showAllLabel
{
    [self.timer invalidate];
    [self.viewsArray enumerateObjectsUsingBlock:^(ACCToolBarItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj showLabelWithDuration:kACCToolBarViewLabelShowDuration];
    }];
    [self.moreButtonView showLabelWithDuration:kACCToolBarViewLabelShowDuration];
    self.labelShowing = YES;
}

- (void) p_checkAndShowBubble
{
    @weakify(self);
    [self.viewsArray enumerateObjectsUsingBlock:^(ACCToolBarItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // check and show it one time
        @strongify(self);
        if (obj.shownFirstTime && [self p_viewInsideScrollFrame:obj]) {
            obj.shownFirstTime = NO;
            ACCBarItem *item = [self p_barItemWithItemId:obj.itemId];
            ACCBLOCK_INVOKE(item.showBubbleBlock);
        }
    }];
}

- (ACCBarItem *)p_barItemWithItemId:(void *)itemId
{
    __block ACCBarItem *item = nil;
    [self.itemsArray enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.itemId == itemId) {
            item = obj;
            *stop = YES;
        }
    }];
    return item;
}

- (BOOL) p_viewInsideScrollFrame:(UIView *)view
{
    NSUInteger index = [self.scrollStackView.stackView.arrangedSubviews indexOfObject:view] + 1;
    BOOL hasView = index >= 1 && index <= [self numberOfAllItems];
    NSUInteger folded = [self p_numberOfItemsFolded];
    NSUInteger all = [self numberOfAllItems];
    BOOL inside = NO;
    if (!hasView) {
        return NO;
    }

    if (self.folded) {
        inside = index <= folded;
    } else {
        inside = index <= all;
    }
    return inside;
}

- (void)clickedBarItemType:(ACCBarItemFunctionType)type
{
    self.folded = YES;
    [self layoutUIWithFolded:self.folded];
}

#pragma mark - PointInside
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (CGRectContainsPoint(self.scrollStackView.frame, point) || CGRectContainsPoint(self.moreButtonView.frame, point))
    {
        return YES;
    }
    return NO;
}

@end
