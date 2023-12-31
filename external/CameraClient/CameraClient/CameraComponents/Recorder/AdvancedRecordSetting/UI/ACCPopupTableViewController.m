//
//  ACCPopupTableViewController.m
//  Indexer
//
//  Created by Shichen Peng on 2021/10/27.
//

#import "ACCPopupTableViewController.h"
#import "ACCPopupTableViewController+Delegate.h"
#import "ACCPopupTableViewController+DataSource.h"

// CreationKitInfra
#import <CreationKitInfra/UIView+ACCMasonry.h>

// CreativeKit
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

// CameraClient
#import <CameraClient/ACCViewControllerProtocol.h>


static const CGFloat kAdvanceSettingsHeaderHeight = 24.0f;
static const CGFloat kAdvanceSettingCellHeight = 56.0f;

@interface ACCPopupTableViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *headView;
@property (nonatomic, strong) UIView *headBar;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) id<ACCPopupTableViewDataManagerProtocol> dataManager;

@property (nonatomic, strong) UIView *accessibilityViewToback;

@property (nonatomic, assign) CGPoint startCenter;

@end

ACCContextId(ACCAdvancedRecordSettingContext)

@implementation ACCPopupTableViewController

@synthesize delegate = _delegate;

- (instancetype)initWithDataManager:(id<ACCPopupTableViewDataManagerProtocol>)dataManager
{
    if (self = [self init]) {
        _dataManager = dataManager;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_setupGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self p_updateConstraint];
    [self.tableView reloadData];
    [self.containerView setHidden:NO];
}

#pragma mark - ACCPopupTableViewControllerProtocol

- (CGFloat)contentHeight
{
    CGFloat Height = [self.dataManager.selectedItems count] * kAdvanceSettingCellHeight + kAdvanceSettingsHeaderHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
    return Height;
}

#pragma mark - UI

- (void)p_setupUI
{
    self.navigationController.navigationBarHidden = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    [ACCViewControllerService() viewController:self setPrefersNavigationBarHidden:YES];
    
    [self.view addSubview:self.containerView];
    [self.view insertSubview:self.accessibilityViewToback belowSubview:self.containerView];
    [self.headView addSubview:self.headBar];
    [self.containerView addSubview:self.headView];
    [self.containerView addSubview:self.tableView];
    
    [self p_makeConstraint];
    
    [self.tableView reloadData];
}

- (void)p_makeConstraint
{
    ACCMasMaker(self.accessibilityViewToback, {
        make.width.equalTo(self.view);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.containerView);
    });
    
    ACCMasMaker(self.containerView, {
        make.width.equalTo(self.view);
        make.height.equalTo(@([self contentHeight]));
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    });
    
    ACCMasMaker(self.headBar, {
        make.height.equalTo(@4);
        make.width.equalTo(@36);
        make.center.equalTo(self.headView);
    });
    
    ACCMasMaker(self.headView, {
        make.left.right.top.equalTo(self.containerView);
        make.height.equalTo(@(kAdvanceSettingsHeaderHeight));
    });
    
    ACCMasMaker(self.tableView, {
        make.top.equalTo(self.headView.mas_bottom);
        make.left.right.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView);
    });
}

- (void)p_updateConstraint
{
    ACCMasReMaker(self.containerView, {
        make.width.equalTo(self.view);
        make.height.equalTo(@([self contentHeight]));
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
    });
    
    ACCMasReMaker(self.accessibilityViewToback, {
        make.width.equalTo(self.view);
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.containerView);
    });
    
    [self drawCorner];
}

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:CGRectMake(0, ACC_SCREEN_HEIGHT, ACC_SCREEN_WIDTH, [self contentHeight])];
        _containerView.backgroundColor = ACCDynamicResourceColor(ACCColorBGReverse);
        _containerView.clipsToBounds = YES;
        [self drawCorner];
    }
    return _containerView;
}

- (void)drawCorner
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self contentHeight]) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12, 12)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self contentHeight] + kAdvanceSettingsHeaderHeight);
    maskLayer.path = path.CGPath;
    _containerView.layer.mask = maskLayer;
}

- (UIView *)headView
{
    if (!_headView) {
        _headView = [[UIView alloc] init];
        _headView.backgroundColor = ACCDynamicResourceColor(ACCColorBGReverse);
    }
    return _headView;
}

- (UIView *)headBar
{
    if (!_headBar) {
        _headBar = [[UIView alloc] init];
        _headBar.backgroundColor = ACCDynamicResourceColor(ACCColorLineReverse);
        _headBar.clipsToBounds = YES;
        _headBar.layer.cornerRadius = 2;
    }
    return _headBar;
}

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.backgroundColor = ACCDynamicResourceColor(ACCColorBGReverse);
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.scrollEnabled = NO;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
//        [_tableView adaptIOS11];
        [self registerTableViewCellReuse];
    }
    return _tableView;
}

- (UIView *)accessibilityViewToback
{
    if (!_accessibilityViewToback) {
        _accessibilityViewToback = [[UIView alloc] init];
        _accessibilityViewToback.isAccessibilityElement = YES;
        _accessibilityViewToback.accessibilityLabel = @"关闭面板";
        _accessibilityViewToback.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return _accessibilityViewToback;
}

- (void)registerTableViewCellReuse
{
    [self.dataManager.items enumerateObjectsUsingBlock:^(id<ACCPopupTableViewDataItemProtocol>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Class cellClass = obj.cellClass;
        [self.tableView registerClass:cellClass forCellReuseIdentifier:[cellClass description]];
    }];
}


- (BOOL)accessibilityPerformEscape
{
    [self dismissViewControllerAnimated:YES completion:nil];
    return YES;
}

#pragma mark - UIGestureRecognizer

- (void)p_setupGestureRecognizer
{
    [self addTapGestureToView:self.accessibilityViewToback withSelector:@selector(tapToDismiss:)];
    [self addPanGestureToView:self.containerView withSelector:@selector(handlePanToDismiss:)];
}

- (void)addTapGestureToView:(UIView *)view withSelector:(SEL)selector
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:selector];
    tap.cancelsTouchesInView = NO;
    [view addGestureRecognizer:tap];
}

- (void)addPanGestureToView:(UIView *)view withSelector:(SEL)selector
{
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:selector];
    pan.delegate = self;
    [view addGestureRecognizer:pan];
}

- (void)tapToDismiss:(UIGestureRecognizer *)gesture
{
    if ([self.delegate conformsToProtocol:@protocol(ACCPopupTableViewControllerDelegateProtocol)]) {
        [self.delegate dismissPanel];
    }
}

- (void)handlePanToDismiss:(UIPanGestureRecognizer *)gesture
{
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            self.startCenter = self.containerView.center;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint translation = [gesture translationInView:self.containerView];
            CGPoint center = CGPointMake(self.containerView.center.x, self.containerView.center.y + translation.y);
            if (center.y < self.startCenter.y) {
                center.y = self.startCenter.y;
            }
            self.containerView.center = center;
            [gesture setTranslation:CGPointZero inView:self.containerView];

            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            CGFloat movedDistance = self.containerView.center.y - self.startCenter.y;
            
            if (movedDistance > 0 && movedDistance > [self contentHeight] * 0.3) {
                [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    CGPoint nextPosition = self.containerView.center;
                    nextPosition.y += [self contentHeight];
                    self.containerView.center = nextPosition;
                } completion:^(BOOL finished) {
                    [self.containerView setHidden:YES];
                    if ([self.delegate conformsToProtocol:@protocol(ACCPopupTableViewControllerDelegateProtocol)]) {
                        [self.delegate dismissPanel];
                    }
                }];
            } else {
                [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.containerView.center = self.startCenter;
                } completion:^(BOOL finished) {
                    
                }];
            }
            break;
        }
        default: {
            break;
        }
    }
}

#pragma mark - ACCPanelViewProtocol

- (CGFloat)panelViewHeight
{
    return self.view.frame.size.height;
}

- (void *)identifier
{
    return ACCAdvancedRecordSettingContext;
}

@end
