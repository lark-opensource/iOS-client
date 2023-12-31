//
//  ACCEditBottomToolBarContainer.m
//  CameraClient
//
//  Created by wishes on 2020/6/4.
//

#import "ACCEditBottomToolBarContainer.h"
#import "AWEEditActionContainerView.h"
#import "AWEXScreenAdaptManager.h"

static const CGFloat kAWEEditAndPublishViewLeftBottomMargin = 16;
static const CGFloat kAWEEditAndPublishViewLeftBottomItemSpacing = 20;
static const CGFloat kAWEEditAndPublishViewLeftBottomItemWidth = 56.0;

@interface ACCEditBottomToolBarContainer ()

@property (nonatomic,strong) AWEEditActionContainerView* barContentView;

@end

@implementation ACCEditBottomToolBarContainer

- (instancetype)initWithContentView:(UIView *)contentView
{
    if (self = [super initWithContentView:contentView]) {
        self.contentView = contentView;
        self.location = ACCBarItemResourceLocationBottom;
    }
    return self;
}

- (void)containerViewDidLoad {
    [self setUpContentToolBar];
}


- (UIView *)barItemContentView {
    return self.barContentView;
}

- (void)setUpContentToolBar {
    UIEdgeInsets leftBottomContainerInset = UIEdgeInsetsMake(0, kAWEEditAndPublishViewLeftBottomMargin, 0, kAWEEditAndPublishViewLeftBottomMargin);
    CGFloat leftBottomItemSpacing = kAWEEditAndPublishViewLeftBottomItemSpacing;
    AWEEditActionContainerViewLayout *layout = [AWEEditActionContainerViewLayout new];
    layout.itemSpacing = leftBottomItemSpacing;
    layout.contentInset = leftBottomContainerInset;

    self.barContentView = [[AWEEditActionContainerView alloc] initWithItemDatas:[self adaptBarItemToViewData] containerViewLayout:layout];
    CGSize size = self.barContentView.intrinsicContentSize;
    [self.contentView addSubview:self.barContentView];
    @weakify(self)
    [self.barContentView.itemViews enumerateObjectsUsingBlock:^(AWEEditActionItemView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.itemViewDidClicked = ^(AWEEditActionItemView * _Nonnull itemView) {
            @strongify(self)
            ACCBLOCK_INVOKE(self.clickCallback, itemView);
            ACCBLOCK_INVOKE(itemView.itemData.actionBlock, self.contentView, itemView);
        };
    }];
    CGFloat offsetY = ACC_SCREEN_HEIGHT - ACC_IPHONE_X_BOTTOM_OFFSET - 17 - size.height;
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        offsetY = ACC_SCREEN_HEIGHT - ACC_IPHONE_X_BOTTOM_OFFSET - 54.0;
    }
    
    self.barContentView.frame = CGRectMake(0, offsetY, size.width, size.height);
}

#pragma mark - Utils

- (CGFloat)bottomItemSpacing
{
    if ([self adaptBarItemToViewData].count > 5) {
        return (ACC_SCREEN_WIDTH - kAWEEditAndPublishViewLeftBottomMargin - kAWEEditAndPublishViewLeftBottomItemWidth * 5.5) / 5.0;
    }
    
    return kAWEEditAndPublishViewLeftBottomItemSpacing;
}

@end
