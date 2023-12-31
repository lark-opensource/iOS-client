//
//  ACCRecorderToolBarContainerAdapter.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/1.
//

#import "ACCToolBarContainerAdapter.h"
#import "ACCToolBarContainer.h"

#import <CreativeKit/ACCPanelViewController.h>

@interface  ACCToolBarContainerAdapter() <ACCPanelViewDelegate>
@property (nonatomic, strong) ACCToolBarContainer *container;
@property (nonatomic, assign) ACCToolBarContainerPageEnum page;
@end

@implementation ACCToolBarContainerAdapter

@synthesize clickCallback = _clickCallback;
@synthesize contentView = _contentView;
@synthesize location = _location;
@synthesize maxHeightValue = _maxHeightValue;
@synthesize moreItemView = _moreItemView;
@synthesize sortDataSource = _sortDataSource;

- (instancetype)initWithContentView:(UIView *)contentView Page:(ACCToolBarContainerPageEnum)page
{
    self = [super init];
    if (self) {
        _page = page;
        _container = [[ACCToolBarContainer alloc] initWithContentView:contentView Page:page];
    }
    return self;
}

- (void)containerViewDidLoad
{
    [self.container containerViewDidLoad];
}

#pragma mark BarItems

- (BOOL)addBarItem:(nonnull ACCBarItem *)item
{
    return [self.container addBarItem:item];
}

- (void)removeBarItem:(nonnull void *)itemId
{
    [self.container removeBarItem:itemId];
}

- (nonnull NSArray<ACCBarItem *> *)barItems
{
    return [self.container barItems];
}

- (nonnull ACCBarItem *)barItemWithItemId:(nonnull void *)itemId
{
    return [self.container barItemWithItemId:itemId];
}

#pragma mark - View

- (id<ACCBarItemCustomView>)viewWithBarItemID:(nonnull void *)itemId
{
    return [self.container viewWithBarItemID:itemId];
}

- (nonnull UIView *)barItemContentView
{
    return [self.container barItemContentView];
}

- (void)addMaskViewAboveToolBar:(UIView *)maskView
{
    return;
}

#pragma mark - Update
- (void)updateAllBarItems
{
    [self.container updateAllBarItems];
}

- (void)updateBarItemWithItemId:(nonnull void *)itemId
{
    [self.container updateBarItemWithItemId:itemId];
}

- (void)resetFoldState
{
    [self.container resetFoldState];
}

- (void)resetShrinkState
{
    [self.container resetShrikState];
}

- (void)resetUpBarContentView
{
    [self.container resetUpBarContentView];
}

- (void)setMoreTouchUpEvent:(nonnull EditToolBarMoreClickEvent)event {
    self.container.clickMoreBlock = event;
}

- (void)forceInsertWithBarItemIdsArray:(NSArray<NSValue *> *)ids
{
    [self.container forceInsertWithBarItemIdsArray:ids];
}

#pragma mark - panel view delegate
- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView
{
    [self.container onPanelViewDismissed];
}

@end
