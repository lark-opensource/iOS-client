//
//  AWERecoderToolBarContainer.m
//  AWEStudio
//
//  Created by Liu Deping on 2020/3/25.
//

#import "AWERecoderToolBarContainer.h"
#import "AWECameraContainerFeatureButtonScrollView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CameraClient/ACCConfigKeyDefines.h>

ACCContextId(ACCRecorderToolBarSwapContext)
ACCContextId(ACCRecorderToolBarSpeedControlContext)
ACCContextId(ACCRecorderToolBarFilterContext)
ACCContextId(ACCRecorderToolBarModernBeautyContext)
ACCContextId(ACCRecorderToolBarDelayRecordContext)
ACCContextId(ACCRecorderToolBarDuetLayoutContext)
ACCContextId(ACCRecorderToolBarMicrophoneContext)
ACCContextId(ACCRecorderToolBarFlashContext)
ACCContextId(ACCRecorderToolBarInspirationContext)
ACCContextId(ACCRecorderToolBarMeteorModeContext)
ACCContextId(ACCRecorderToolBarRecognitionContext)
ACCContextId(ACCRecorderToolBarEarBackContext)
ACCContextId(ACCRecorderToolBarAdvancedSettingContext)

@interface AWERecoderToolBarContainer ()

@property (nonatomic, weak) UIView *contentView;

@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) NSMutableArray<ACCBarItem *> *barItems;

@property (nonatomic, strong) AWECameraContainerFeatureButtonScrollView *toolBarContentView;

@property (nonatomic, assign) BOOL itemLoaded;


@end

@implementation AWERecoderToolBarContainer

@synthesize sortDataSource = _sortDataSource;
@synthesize delegate = _delegate;

- (instancetype)initWithContentView:(UIView *)contentView
{
    if (self = [super init]) {
        _containerView = [[UIView alloc] init];
        _containerView.clipsToBounds = YES;
        _contentView = contentView;
        _toolBarContentView = [AWECameraContainerFeatureButtonScrollView new];
    }
    return self;
}

- (void)setSortDataSource:(id<ACCBarItemSortDataSource>)sortDataSource
{
    _sortDataSource = sortDataSource;
    self.toolBarContentView.sortDataSrouce = sortDataSource;
}

- (BOOL)addBarItem:(ACCBarItem *)item
{
    if (!item) {
        return NO;
    }
    
    if (!item.customView) {
        item.customView = [self p_createToolBarCustomViewWithBarItem:item];
    } else {
        @weakify(self);
        @weakify(item);
        item.customView.itemViewDidClicked = ^(UIButton * _Nonnull sender) {
            @strongify(item);
            @strongify(self);
            if ([self.delegate respondsToSelector:@selector(barItemContainer:didClickedBarItem:)]) {
                [self.delegate barItemContainer:self didClickedBarItem:item.itemId];
            }
        };
    }
    item.customView.needShow = item.needShowBlock();
    [self.barItems addObject:item];
    [self.toolBarContentView addFeatureView:(AWECameraContainerToolButtonWrapView *)item.customView];
    [self p_layoutBarItemContentView];
    return NO;
}

- (void)removeBarItem:(void *)itemId
{
    NSAssert(false, @"not implement");
}

- (id<ACCBarItemCustomView>)viewWithBarItemID:(void *)itemId
{
    id<ACCBarItemCustomView> view = [self.toolBarContentView getViewForBarItem:[self barItemWithItemId:itemId]];
    return view;
}

- (void)addMaskViewAboveToolBar:(UIView *)maskView
{
    [self.toolBarContentView insertMaskViewAboveToolBar:maskView];
}

- (void)containerViewDidLoad
{
    if (_toolBarContentView.superview != self.contentView) {
        [self.contentView addSubview:self.containerView];
        [self.containerView addSubview:self.toolBarContentView];
        [self p_deferedLayoutBarItemContentView];
    }
    
    self.itemLoaded = YES;
}

- (void)p_sortItems
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
    self.barItems = [sort(self.barItems) mutableCopy];
}

- (void)p_layoutBarItemContentView
{
    SEL defered = @selector(p_deferedLayoutBarItemContentView);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:defered object:nil];
    [self performSelector:defered withObject:nil afterDelay:0.1];
}

- (void)p_deferedLayoutBarItemContentView
{
    CGFloat rightSpacing = 2;
    CGFloat featureViewHeight = 48;
    CGFloat featureViewWidth = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 48.0 : 52;
    CGFloat buttonSpacing = [UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5 ? 2.0 : 14.0;
    CGFloat buttonHeightWithSpacing = buttonSpacing + featureViewHeight;
    
    CGRect tempFrame = CGRectMake(6, 20, featureViewWidth, featureViewHeight);
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            tempFrame = CGRectMake(6, ACC_STATUS_BAR_NORMAL_HEIGHT + kYValueOfRecordAndEditPageUIAdjustment, featureViewWidth, featureViewHeight);
        }
    }
    
    CGFloat topOffset = (tempFrame.origin.y + featureViewHeight * 0.5) - featureViewHeight * 0.5 + 6.0;//6 is back button's image's edge

    if (!self.contentView || !self.containerView || !self.toolBarContentView) {
        return;
    }

    ACCMasMaker(self.containerView, {
        make.leading.equalTo(self.contentView.mas_trailing).offset(-(rightSpacing + featureViewWidth));
        make.top.equalTo(self.contentView).offset(topOffset);
        make.width.equalTo(@(featureViewWidth));
        make.height.equalTo(@(self.toolBarContentView.visibleButtons.count * buttonHeightWithSpacing));
    });
    
    ACCMasMaker(self.toolBarContentView, {
        make.leading.trailing.equalTo(self.containerView);
        make.width.equalTo(@(featureViewWidth));
        make.height.equalTo(@(self.toolBarContentView.visibleButtons.count * buttonHeightWithSpacing));
    });
}

- (ACCBarItem *)barItemWithItemId:(void *)itemId
{
    __block ACCBarItem *barItem;
    [self.barItems enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.itemId ==  itemId) {
            barItem = obj;
        }
    }];
    return barItem;
}

- (void)updateBarItemWithItemId:(void *)itemId
{
    ACCBarItem *item = [self barItemWithItemId:itemId];
    if (item) {
        NSAssert(item.customView != nil, @"barItem instance should bind a customView");
        NSAssert(item.needShowBlock != nil, @"barItem instance's needShowBlock can not be nil");
        item.customView.needShow = item.needShowBlock();
        [UIView animateWithDuration:0.25 animations:^{
            if (item.customView.needShow) {
                [self.toolBarContentView insertItem:item];
            } else {
                [self.toolBarContentView removeItem:item];
            }
            [self p_layoutBarItemContentView];
        }];
    }
}

- (void)updateAllBarItems
{
    // sort the items before update, otherwise the icon would not dismiss in order.
    [self p_sortItems];
    @weakify(self);
    [self.barItems enumerateObjectsUsingBlock:^(ACCBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop){
        @strongify(self);
        [self updateBarItemWithItemId:obj.itemId];
    }];
    [self p_layoutBarItemContentView];
}

- (NSMutableArray<ACCBarItem *> *)barItems
{
    if (!_barItems) {
        _barItems = @[].mutableCopy;
    }
    return _barItems;
}

- (UIView<ACCBarItemCustomView> *)p_createToolBarCustomViewWithBarItem:(ACCBarItem *)barItem
{
    UILabel *titleLabel = [self p_createBarItemLabel:barItem];
    UIButton *barItemButton = [self p_createBarItemButton:barItem];
    UIView<ACCBarItemCustomView> *customView = [[AWECameraContainerToolButtonWrapView alloc] initWithButton:barItemButton label:titleLabel itemID:barItem.itemId];
    @weakify(barItem);
    @weakify(self);
    customView.itemViewDidClicked = ^(UIButton * _Nonnull sender) {
        @strongify(barItem);
        @strongify(self);
        ACCBLOCK_INVOKE(barItem.barItemActionBlock, sender);
        if ([self.delegate respondsToSelector:@selector(barItemContainer:didClickedBarItem:)]) {
            [self.delegate barItemContainer:self didClickedBarItem:barItem.itemId];
        }
    };
    return customView;
}

- (UIButton *)p_createBarItemButton:(ACCBarItem *)barItem
{
    UIButton *barItemButton = nil;
    if (barItem.useAnimatedButton) {
        barItemButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
    } else {
        barItemButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    [barItemButton setImage:ACCResourceImage(barItem.imageName) forState:UIControlStateNormal];
    if (barItem.selectedImageName) {
        [barItemButton setImage:ACCResourceImage(barItem.selectedImageName) forState:UIControlStateSelected];
    }
    barItemButton.accessibilityLabel = [barItem.title copy];
    barItemButton.adjustsImageWhenHighlighted = NO;
    return barItemButton;
}

- (UILabel *)p_createBarItemLabel:(ACCBarItem *)barItem
{
    if (!barItem.title) {
        return nil;
    }
    UILabel *label = [[UILabel alloc] acc_initWithFont:[ACCFont() acc_boldSystemFontOfSize:10]
                                             textColor:ACCResourceColor(ACCUIColorConstTextInverse)
                                                  text:barItem.title];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
    label.isAccessibilityElement = NO;
    return label;
}

- (UIView *)barItemContentView
{
    return self.containerView;
}

@end


