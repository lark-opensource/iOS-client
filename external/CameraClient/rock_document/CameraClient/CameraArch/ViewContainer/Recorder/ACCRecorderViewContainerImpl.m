//
//  ACCRecorderViewContainerImpl.m
//  CameraClient
//
//  Created by Liu Deping on 2020/2/25.
//

#import "ACCRecorderViewContainerImpl.h"
#import "ACCInteractionView.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCPanelViewController.h>
#import <CreativeKit/ACCBarItemContainerView.h>
#import <CreativeKit/ACCLayoutContainerProtocol.h>
#import "AWESwitchRecordModeView.h"
#import "ACCPassThroughView.h"
#import <CreationKitRTProtocol/ACCCameraSubscription.h>
#import "ACCRecordLayoutManager.h"
#import <Masonry/Masonry.h>

@interface ACCRecorderViewContainerImpl ()

@property (nonatomic, weak) UIView *rootView;
@property (nonatomic, assign) BOOL itemsShouldHide;

@property (nonatomic, strong) ACCCameraSubscription *subscription;
@property (nonatomic, strong, readwrite) ACCInteractionView *interactionView;

@end

@implementation ACCRecorderViewContainerImpl

@synthesize barItemContainer = _barItemContainer;
@synthesize modeSwitchView = _modeSwitchView;
@synthesize panelViewController = _panelViewController;
@synthesize preview = _preview;
@synthesize popupContainerView = _popupContainerView;
@synthesize layoutManager = _layoutManager;
@synthesize switchModeContainerView = _switchModeContainerView;
@synthesize isShowingPanel = _isShowingPanel;
@synthesize isShowingMVDetailVC = _isShowingMVDetailVC;
@synthesize propPanelType = _propPanelType;
@synthesize shouldClearUI = _shouldClearUI;
@synthesize interactionBlock;

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithRootView:(UIView *)rootView
{
    if (self = [super init]) {
        _rootView = rootView;
        _interactionView = [[ACCInteractionView alloc] initWithFrame:rootView.bounds];;
        [_rootView addSubview:_interactionView];
        [_interactionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_rootView);
        }];
        _preview = [[UIView alloc] initWithFrame:rootView.bounds];
        [_interactionView addSubview:_preview];
        [_preview mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_interactionView);
        }];
        _panelViewController = [[ACCPanelViewController alloc] initWithContainerView:rootView];
        _modeSwitchView = [[ACCPassThroughView alloc] initWithFrame:rootView.bounds];
        [_rootView addSubview:_modeSwitchView];
        [_modeSwitchView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_rootView);
        }];
        
        _popupContainerView = [[ACCPassThroughView alloc] initWithFrame:rootView.bounds];
        [_rootView addSubview:_popupContainerView];
        [_popupContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(_rootView);
        }];
    }
    return self;
}

- (void)setInteractionBlock:(dispatch_block_t)interactionBlock {
    self.interactionView.interactionBlock = interactionBlock;
}

- (void)viewContainerDidLoad
{
    [self.barItemContainer containerViewDidLoad];
    [self.layoutManager containerViewControllerPostDidLoad];
}

- (void)containerViewDidLayoutSubviews
{
    [self.layoutManager containerViewControllerPostDidLoad];
    [self.switchModeContainerView.collectionView.collectionViewLayout invalidateLayout];
}

- (void)addObserver:(id<ACCRecorderViewContainerItemsHideShowObserver>)observer
{
    if (!observer) {
        return;
    }
    [self.subscription addSubscriber:observer];
}

- (void)removeObserver:(id<ACCRecorderViewContainerItemsHideShowObserver>)observer
{
    if (!observer) {
        return;
    }
    [self.subscription removeSubscriber:observer];
}

- (void)showItems:(BOOL)show animated:(BOOL)animated
{
    self.itemsShouldHide = !show;
    [self.subscription performEventSelector:@selector(shouldItemsShow:animated:) realPerformer:^(id<ACCRecorderViewContainerItemsHideShowObserver> observer) {
        [observer shouldItemsShow:show animated:animated];
    }];
}

- (void)injectBarItemContainer:(id<ACCRecorderBarItemContainerView>)barItemContainer
{
    if (!_barItemContainer && [barItemContainer conformsToProtocol:@protocol(ACCRecorderBarItemContainerView)]) {
        _barItemContainer = barItemContainer;
    }
}

- (id<ACCLayoutContainerProtocol>)layoutManager
{
    if (_layoutManager == nil) {
        ACCRecordLayoutManager *layoutManager = [[ACCRecordLayoutManager alloc] init];
        layoutManager.interactionView = self.interactionView;
        layoutManager.rootView = self.rootView;
        layoutManager.modeSwitchView = self.modeSwitchView;
        _layoutManager = layoutManager;
    }
    return _layoutManager;
}

- (UIView<ACCSwitchModeContainerView> *)switchModeContainerView
{
    if (_switchModeContainerView == nil) {
        CGFloat height = 40;
        CGFloat frameY = CGRectGetMaxY(_interactionView.frame) - height - ACC_IPHONE_X_BOTTOM_OFFSET - 6;
        CGRect frame = CGRectMake(0, frameY, CGRectGetWidth(_interactionView.frame), height);
        _switchModeContainerView =  [[AWESwitchRecordModeView alloc] initWithFrame:frame];
        [self.layoutManager addSubview:_switchModeContainerView viewType:ACCViewTypeSwitchMode];
    }
    return _switchModeContainerView;
}

- (void)setPropPanelType:(ACCRecordPropPanelType)propPanelType
{
    _propPanelType = propPanelType;
    if (propPanelType == ACCRecordPropPanelNone) {
        
    }
}

- (ACCCameraSubscription *)subscription {
    if (!_subscription) {
        _subscription = [ACCCameraSubscription new];
    }
    return _subscription;
}

- (BOOL)isShowingAnyPanel
{
    return self.isShowingPanel || self.propPanelType != ACCRecordPropPanelNone;
}
@end
