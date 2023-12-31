//
//  ACCToolBarContainer.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/1.
//

#import "ACCToolBarContainer.h"
#import "ACCToolBarCommonViewLayout.h"
#import "ACCToolBarItemsModel.h"
#import "ACCToolBarSortDataSource.h"
#import "ACCToolBarFoldView.h"
#import "ACCToolBarPageView.h"
#import "ACCToolBarAdapterUtils.h"
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/UIDevice+ACCHardware.h>
#import <CreativeKit/ACCMacros.h>
#import <CameraClient/AWERecorderTipsAndBubbleManager.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>


@interface ACCToolBarContainer ()<UIGestureRecognizerDelegate>
@property (nonatomic, weak) UIView *contentView; // interaction View which contains toolBarView
@property (nonatomic, assign) ACCToolBarContainerPageEnum page;
@property (nonatomic, strong) ACCToolBarItemsModel *model;
@property (nonatomic, strong) ACCToolBarView *toolBarView;
@property (nonatomic, strong) NSMutableArray *forceInsertArray;
@property (nonatomic, strong) UIView *toolBarShadowView;
@end

/* Use Steps:
1. Create Container instance
2. Components add BarItems
3. Config Container UI
 */

@implementation ACCToolBarContainer

@synthesize clickItemBlock = _clickItemBlock; // 如果点击了Item，就调用

@synthesize clickMoreBlock = _clickMoreBlock; // 如果点击了More，就调用

@synthesize sortDataSource = _sortDataSource;

- (instancetype)initWithContentView:(UIView *)contentView Page:(ACCToolBarContainerPageEnum)page;
{
    if (self = [super init]) {
        _page = page;
        _contentView = contentView;
        _forceInsertArray = [NSMutableArray array];
        _model = [[ACCToolBarItemsModel alloc] init];
        _sortDataSource = [[ACCToolBarSortDataSource alloc] init];
    }
    return self;
}

- (BOOL)addBarItem:(nonnull ACCBarItem *)item {
    return [self.model addBarItem:item];
}

- (nonnull UIView *)barItemContentView {
    return self.toolBarView;
}

- (ACCBarItem *)barItemWithItemId:(nonnull void *)itemId {
    return [self.model barItemWithItemId:itemId];
}

- (nonnull NSArray<ACCBarItem *> *)barItems {
    return [self.model barItems];
}

- (void)removeBarItem:(nonnull void *)itemId {
    [self.model removeBarItem:itemId];
}

- (void)containerViewDidLoad {
    // init UI here
    [self p_setUpUI];
}

- (void)p_setUpUI
{
    ACCToolBarCommonViewLayout *layout = [[ACCToolBarCommonViewLayout alloc] init];
    layout.direction = ACCToolBarViewLayoutDirectionVertical;
    layout.itemSpacing = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 2.0 : 14.0;;
    layout.moreButtonSpacing = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 2.0 : 14.0;;
    layout.itemSize = CGSizeMake(32, 32);
    layout.moreButtonSize = CGSizeMake(32, 32);

    BOOL isEdit = self.page == ACCToolBarContainerPageEnumEdit || self.page == ACCToolBarContainerPageEnumIMEdit;
    NSArray *ordersArray = [(ACCToolBarSortDataSource *)self.sortDataSource barItemSortArrayWithPage:self.page];
    NSArray *redpointArray = [(ACCToolBarSortDataSource *)self.sortDataSource  barItemRedPointArrayWithPage:self.page];

    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        _toolBarView = [[ACCToolBarFoldView alloc] initWithLayout:layout itemsData:[self barItems] ordersArray:ordersArray redPointArray:redpointArray forceInsertArray:self.forceInsertArray isEdit:isEdit];
    } else if ([ACCToolBarAdapterUtils useToolBarPageStyle]) {
        _toolBarView = [[ACCToolBarPageView alloc] initWithLayout:layout itemsData:[self barItems] ordersArray:ordersArray redPointArray:redpointArray forceInsertArray:self.forceInsertArray isEdit:isEdit];
    } else {
        _toolBarView = [[ACCToolBarFoldView alloc] initWithLayout:layout itemsData:[self barItems] ordersArray:ordersArray redPointArray:redpointArray forceInsertArray:self.forceInsertArray isEdit:isEdit];
    }

    [_contentView addSubview:_toolBarView];

    CGFloat topMargin = 26;
    CGFloat rightMargin = [ACCToolBarAdapterUtils useToolBarPageStyle] ? -9 : -13;
    
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            topMargin = ACC_STATUS_BAR_NORMAL_HEIGHT + kYValueOfRecordAndEditPageUIAdjustment + 6;
        }
    }
    ACCMasMaker(self.toolBarView, {
        make.top.mas_equalTo(self.contentView).offset(topMargin);
        make.right.mas_equalTo(self.contentView.mas_right).offset(rightMargin);
        make.bottom.equalTo(self.contentView);
    });

    @weakify(self);
    self.toolBarView.clickItemBlock = ^(UIView * _Nonnull clickItemView) {
        @strongify(self);
        [self showToolBarShadowViewWithFolded:YES];
        ACCBLOCK_INVOKE(self.clickItemBlock, clickItemView);
    };

    self.toolBarView.clickMoreBlock = ^(BOOL foldedAfterclick) {
        @strongify(self);
        [self showToolBarShadowViewWithFolded:foldedAfterclick];
        ACCBLOCK_INVOKE(self.clickMoreBlock, foldedAfterclick);
        if (!isEdit) {
            [[AWERecorderTipsAndBubbleManager shareInstance] clearAll];
        }
    };

    [self.toolBarView setupUI];
    [self.contentView layoutIfNeeded];
    
}

- (void)showToolBarShadowViewWithFolded:(BOOL)foldedAfterClicked
{
    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        CGFloat alpha = foldedAfterClicked ? 0 : 1;
        if (ACC_FLOAT_EQUAL_TO(alpha, self.toolBarShadowView.alpha)) {
            return;
            
        }
        [UIView animateWithDuration:0.3 animations:^{
            self.toolBarShadowView.alpha = alpha;
        }];
    }
}

- (UIView *)toolBarShadowView
{
    if (!_toolBarShadowView) {
        CGRect frame = self.contentView.frame;
        frame.origin.x += 155;
        UIView *toolBarShadowView = [[UIView alloc] initWithFrame:frame];
        CAGradientLayer *gradientLayer = [CAGradientLayer layer];
        gradientLayer.colors  = @[(id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0].CGColor,
                             (id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.7].CGColor];
        gradientLayer.locations = @[@0, @1];
        gradientLayer.startPoint = CGPointMake(0.0, 0.5);
        gradientLayer.endPoint = CGPointMake(1.0, 0.5);
        gradientLayer.frame = toolBarShadowView.bounds;

        [toolBarShadowView.layer addSublayer:gradientLayer];
        toolBarShadowView.userInteractionEnabled = NO;
        toolBarShadowView.alpha = 0;
        _toolBarShadowView = toolBarShadowView;

        [self.contentView insertSubview:_toolBarShadowView belowSubview:self.toolBarView];
    }
    return _toolBarShadowView;
}

- (void)updateBarItemWithItemId:(nonnull void *)itemId {
    // update single Item UI
    ACCBarItem *item = [self barItemWithItemId:itemId];
    if (item) {
        NSAssert(item.needShowBlock != nil, @"barItem instance's needShowBlock can not be nil");
        BOOL needShow = item.needShowBlock();
        if (needShow) {
            [self.toolBarView insertItem:item];
        } else {
            [self.toolBarView removeItem:item];
        }
    }
}

- (void)addMaskViewAboveToolBar:(UIView *)maskView {
    //  add mask to UI
    return;
}

- (UIView *)getMoreItemView {
    // get UI
    return nil;
}

- (void)resetShrikState
{
    // layout all barItems, hide label
    [self showToolBarShadowViewWithFolded:YES];
    [self.toolBarView resetShrinkState];
}

- (void)updateAllBarItems {
    
    @weakify(self);
    [self.sortedItems enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        @strongify(self);
        [self updateBarItemWithItemId:obj.itemId];
    }];
    // layout all barItems
    [self showToolBarShadowViewWithFolded:YES];
    [self.toolBarView resetFoldState];
}

- (void)resetUpBarContentView {
    // reset UI 4s
    [self showToolBarShadowViewWithFolded:YES];
    [self.toolBarView resetUI];
}

- (void)resetFoldState
{
    // reset UI 2.5s
    [self showToolBarShadowViewWithFolded:YES];
    [self.toolBarView resetFoldStateAndShowLabel];
}

- (void)forceInsertWithBarItemIdsArray:(NSArray<NSValue *> *)ids
{
    [self.forceInsertArray addObjectsFromArray:ids];
}

- (id<ACCBarItemCustomView>)viewWithBarItemID:(nonnull void *)itemId {
    if (self.toolBarView != nil) {
        return [self.toolBarView viewWithBarItemID:itemId];
    }
    return nil;
}

- (void)onPanelViewDismissed
{
    [self showToolBarShadowViewWithFolded:YES];
    [self.toolBarView resetFoldStateAndShowLabel];
}

- (NSArray<ACCBarItem *> *)sortedItems
{
    NSArray *itemSortArray = [self.sortDataSource barItemSortArray];
    NSArray<ACCBarItem *> *(^sort) (NSArray<ACCBarItem *> *itemSort) = ^(NSArray<ACCBarItem *> *itemSort) {
        return [itemSort sortedArrayUsingComparator:^NSComparisonResult (ACCBarItem *obj1, ACCBarItem *obj2) {
            NSComparisonResult result = NSOrderedSame;
            if(([itemSortArray indexOfObject:[NSValue valueWithPointer:obj1.itemId]] != NSNotFound) && ([itemSortArray indexOfObject:[NSValue valueWithPointer:obj2.itemId]] != NSNotFound)) {
                NSNumber *index1 = @([itemSortArray indexOfObject:[NSValue valueWithPointer:obj1.itemId]]);
                NSNumber *index2 = @([itemSortArray indexOfObject:[NSValue valueWithPointer:obj2.itemId]]);
                result = [index1 compare:index2];
            }
            return result;
        }];
    };
    return sort(self.barItems);
}

@end
