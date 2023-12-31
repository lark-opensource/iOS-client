//
//  ACCEditTagsPickerViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by HuangHongsen on 2021/9/29.
//

#import "ACCEditTagsPickerViewController.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCSlidingViewController.h>
#import <CreationKitInfra/ACCSlidingTabbarView.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import <CreationKitArch/ACCRepoTrackModel.h>

#import "ACCEditTagsUserPickerViewController.h"
#import "ACCTagsPOIPickerViewController.h"
#import "ACCTagsBrandPickerViewController.h"
#import "ACCTagsCommodityPickerViewController.h"
#import "ACCTagsCustomizeViewController.h"
#import "ACCLocationProtocol.h"
#import "ACCConfigKeyDefines.h"

ACCContextId(ACCEditTagsPickerContext)

@interface ACCEditTagsPickerViewController ()<ACCSlidingViewControllerDelegate, ACCTagsItemPickerViewControllerDelegate>
@property (nonatomic, strong) UIView *topIndicator;
@property (nonatomic, strong) UIView *panelView;

@property (nonatomic, strong) ACCSlidingViewController *slidingViewController;
@property (nonatomic, strong) ACCSlidingTabbarView *slidingTabbarView;
@property (nonatomic, strong) ACCEditTagsUserPickerViewController *userPickerViewController;
@property (nonatomic, strong) ACCTagsPOIPickerViewController *poiPickerViewController;
@property (nonatomic, strong) ACCTagsCommodityPickerViewController *commodityPickerViewController;
@property (nonatomic, strong) ACCTagsCustomizeViewController *customTagsViewController;

@property (nonatomic, copy) NSArray *tabIndecies;
@property (nonatomic, copy) NSArray<NSString *> *titles;
@property (nonatomic, copy) NSArray<ACCTagsItemPickerViewController *> *viewControllers;

@property (nonatomic, assign) BOOL locationAlertDisplayed;
@property (nonatomic, assign) BOOL startTakingTabActions;
@end

@implementation ACCEditTagsPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupDataSource];
    UIView *panelView = [[UIView alloc] init];
    self.panelView = panelView;
    panelView.backgroundColor = ACCResourceColor(ACCColorConstBGContainer);
    [self.view addSubview:panelView];
    ACCMasMaker(panelView, {
        make.edges.equalTo(self.view);
    });
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *bgView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - [self topInset])
                                           byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(12, 12)].CGPath;
    bgView.layer.mask = maskLayer;
    [panelView addSubview:bgView];
    ACCMasMaker(bgView, {
        make.edges.equalTo(panelView);
    });
    
    UIView *gestureView = [[UIView alloc] init];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnTopView)];
    [gestureView addGestureRecognizer:tap];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanOnTopView:)];
    [gestureView addGestureRecognizer:pan];
    gestureView.backgroundColor = [UIColor clearColor];
    [panelView addSubview:gestureView];
    ACCMasMaker(gestureView, {
        make.top.left.right.equalTo(panelView);
        make.height.equalTo(@(36.f));
    });
    
    self.topIndicator = [[UIView alloc] init];
    self.topIndicator.backgroundColor = [UIColor whiteColor];
    self.topIndicator.layer.cornerRadius = 2.f;
    self.topIndicator.layer.masksToBounds = YES;
    [panelView addSubview:self.topIndicator];
    ACCMasMaker(self.topIndicator, {
        make.centerX.equalTo(panelView);
        make.top.equalTo(panelView).offset(10.f);
        make.width.equalTo(@36);
        make.height.equalTo(@4);
    });
    
    self.slidingTabbarView = [[ACCSlidingTabbarView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, 50.f) buttonStyle:ACCSlidingTabButtonStyleText dataArray:nil selectedDataArray:nil];
    self.slidingTabbarView.shouldShowBottomLine = YES;
    self.slidingTabbarView.shouldShowTopLine = NO;
    self.slidingTabbarView.topBottomLineColor = ACCResourceColor(ACCColorConstLineInverse2);
    self.slidingTabbarView.selectionLineColor = ACCResourceColor(ACCColorConstTextInverse);
    [self.slidingTabbarView configureButtonTextFont:[ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium] hasShadow:YES];
    [self.slidingTabbarView resetDataArray:[self titles] selectedDataArray:[self titles]];
    [self.slidingTabbarView configureButtonTextColor:ACCResourceColor(ACCColorConstTextInverse4) selectedTextColor:ACCResourceColor(ACCColorConstTextInverse)];
    
    [panelView addSubview:self.slidingTabbarView];
    ACCMasMaker(self.slidingTabbarView, {
        make.top.equalTo(self.topIndicator.mas_bottom).offset(21.5);
        make.left.right.equalTo(panelView);
        make.height.equalTo(@50);
    });
    
    self.slidingViewController = [[ACCSlidingViewController alloc] initWithSelectedIndex:0];
    self.slidingViewController.tabbarView = self.slidingTabbarView;
    self.slidingViewController.slideEnabled = YES;
    self.slidingViewController.delegate = self;
    self.slidingViewController.view.backgroundColor = [UIColor clearColor];
    [self addChildViewController:self.slidingViewController];
    [panelView addSubview:self.slidingViewController.view];
    [self.slidingViewController didMoveToParentViewController:self];
    
    ACCMasMaker(self.slidingViewController.view, {
        make.top.equalTo(self.slidingTabbarView.mas_bottom);
        make.left.right.bottom.equalTo(panelView);
    });
    
    [self.slidingViewController reloadViewControllers];
    self.slidingViewController.selectedIndex = 0;
    self.startTakingTabActions = YES;
}

- (void)resetPanel
{
    self.panelView.transform = CGAffineTransformIdentity;
    self.locationAlertDisplayed = NO;
    for (ACCTagsItemPickerViewController *viewController in [self viewControllers]) {
        [viewController clearSearchCondition];
    }
}

#pragma mark - Event Handling

- (void)handleTapOnTopView
{
    [self.delegate tagsPickerDidTapTopBar:self];
}

- (void)handlePanOnTopView:(UIPanGestureRecognizer *)pan
{
    CGFloat offset = [pan translationInView:pan.view].y;
    CGFloat yVelocity = [pan velocityInView:pan.view].y;
    CGFloat panelHeight = ACC_SCREEN_HEIGHT - [self topInset];
    if (offset < 0.f) {
        offset = 0.f;
    }
    if (offset > panelHeight) {
        offset = panelHeight;
    }
    CGFloat ratio = offset / panelHeight;
    self.panelView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, offset);
    if (pan.state == UIGestureRecognizerStateBegan || pan.state == UIGestureRecognizerStateChanged) {
        [self.delegate tagsPicker:self didPanWithRatio:ratio finished:NO dismiss:NO];
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        if (yVelocity <= -300.f || (ratio < 0.3 && yVelocity <= 300)) {
            [UIView animateWithDuration:[self animationDuration] * ratio animations:^{
                self.panelView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                [self.delegate tagsPicker:self didPanWithRatio:ratio finished:YES dismiss:NO];
            }];
        } else {
            [UIView animateWithDuration:[self animationDuration] * (1 - ratio) animations:^{
                self.panelView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, panelHeight);
            } completion:^(BOOL finished) {
                [self.delegate tagsPicker:self didPanWithRatio:ratio finished:YES dismiss:YES];
            }];
        }
    }
}

#pragma mark - ACCSlidingViewControllerDelegate

- (NSInteger)numberOfControllers:(ACCSlidingViewController *)slidingController
{
    return [[self viewControllers] count];
}

- (UIViewController *)slidingViewController:(ACCSlidingViewController *)slidingViewController viewControllerAtIndex:(NSInteger)index
{
    return [self viewControllers][index];
}

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didFinishTransitionToIndex:(NSUInteger)index
{
    ACCTagsItemPickerViewController *targetViewController = [self viewControllers][index];
    if ([targetViewController isEqual:self.poiPickerViewController]) {
        if ([ACCLocation() hasPermission]) {
            return ;
        } else {
            [ACCLocation() requestPermissionWithCertName:@"bpea-studio_edit_tag_poi_request_permission" completion:^(ACCLocationPermission permission, NSError * _Nullable error) {
                if (permission == ACCLocationPermissionAlreadyDenied) {
                    if (!self.locationAlertDisplayed) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"位置权限被禁用，请到设置中授予抖音允许访问位置权限" preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:@"去设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                            });
                        }]];
                        
                        [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                        }]];
                        [ACCAlert() showAlertController:alertController animated:YES];
                        self.locationAlertDisplayed = YES;
                    }
                } else if (permission == ACCLocationPermissionAllowed) {
                    [self.poiPickerViewController reloadData];
                }
            }];
        }
    }
}

- (void)slidingViewController:(ACCSlidingViewController *)slidingViewController didSelectIndex:(NSInteger)index transitionType:(ACCSlidingVCTransitionType)transitionType
{
    if (!self.startTakingTabActions) {
        return ;
    }
    ACCTagsItemPickerViewController *targetViewController = [self viewControllers][index];
    NSMutableDictionary *params = [self.baseTrackerParams mutableCopy];
    [params setValue:[targetViewController tagTypeString] forKey:@"tag_type"];
    [ACCTracker() trackEvent:@"change_tag_tab"
                      params:params];
}

#pragma mark - DataSource

- (void)setupDataSource
{
    self.tabIndecies = ACCConfigArray(kConfigArray_tag_creation_tab_order);
    [self setupDataSourceWithIndices:self.tabIndecies];
}

- (void)setupDataSourceWithIndices:(NSArray *)indices
{
    NSMutableArray *titles = [NSMutableArray array];
    NSMutableArray *viewControllers = [NSMutableArray array];
    for (NSNumber *index in indices) {
        switch ([index integerValue]) {
            case ACCEditTagTypeUser: {
                [viewControllers addObject:self.userPickerViewController];
                [titles addObject:[self.userPickerViewController itemTitle]];
            }
                break;
            case ACCEditTagTypePOI: {
                [viewControllers addObject:self.poiPickerViewController];
                [titles addObject:[self.poiPickerViewController itemTitle]];
            }
                break;
            case ACCEditTagTypeCommodity: {
                [viewControllers addObject:self.commodityPickerViewController];
                [titles addObject:[self.commodityPickerViewController itemTitle]];
            }
                break;
            case ACCEditTagTypeSelfDefine: {
                [viewControllers addObject:self.customTagsViewController];
                [titles addObject:[self.customTagsViewController itemTitle]];
            }
                break;
            default:
                break;
        }
    }
    if (!ACC_isEmptyArray(viewControllers)) {
        self.titles = [titles copy];
        self.viewControllers = [viewControllers copy];
    } else {
        self.tabIndecies = @[@(ACCEditTagTypeUser), @(ACCEditTagTypePOI), @(ACCEditTagTypeCommodity), @(ACCEditTagTypeSelfDefine)];
        [self setupDataSourceWithIndices:self.tabIndecies];
    }
}

#pragma mark - ACCPanelViewProtocol

- (void *)identifier
{
    return ACCEditTagsPickerContext;
}

- (CGFloat)panelViewHeight
{
    return ACC_SCREEN_HEIGHT - [self topInset];
}

- (CGFloat)topInset
{
    return ACC_SCREEN_HEIGHT * 0.12;
}

#pragma mark - ACCTagsItemPickerViewControllerDelegate

- (void)tagsItemPicker:(ACCTagsItemPickerViewController *)itemPicker didSelectItem:(AWEInteractionEditTagStickerModel *)item referExtra:(NSDictionary *)referExtra
{
    [self.delegate tagsPicker:self didSelectTag:item originalTag:self.originalTag];
    NSMutableDictionary *params = [[self baseTrackerParams] mutableCopy];
    [params setValue:[itemPicker tagTypeString] forKey:@"tag_type"];
    [params addEntriesFromDictionary:referExtra];
    [ACCTracker() trackEvent:@"tag_complete" params:params];
}

- (void)tagsItemPickerDidTapCreateCustomTagButton:(ACCTagsItemPickerViewController *)itemPicker keyword:(NSString *)keyword
{
    self.customTagsViewController.showCreateCustomAlertOnAppear = YES;
    self.customTagsViewController.defaultCustomTag = keyword;
    self.customTagsViewController.fromTagType = [itemPicker type];
    self.customTagsViewController.fromTagTypeString = [itemPicker tagTypeString];
    self.slidingViewController.selectedIndex = [self.viewControllers indexOfObject:self.customTagsViewController];

}

- (BOOL)isCurrentTagPicker:(ACCTagsItemPickerViewController * _Nonnull)tagsPicker;
{
    NSInteger index = [self.viewControllers indexOfObject:tagsPicker];
    return index == self.slidingViewController.selectedIndex;
}

#pragma mark - Getter

- (ACCEditTagsUserPickerViewController *)userPickerViewController
{
    if (!_userPickerViewController) {
        _userPickerViewController = [[ACCEditTagsUserPickerViewController alloc] init];
        _userPickerViewController.delegate = self;
    }
    return _userPickerViewController;
}

- (ACCTagsPOIPickerViewController *)poiPickerViewController
{
    if (!_poiPickerViewController) {
        _poiPickerViewController = [[ACCTagsPOIPickerViewController alloc] init];
        _poiPickerViewController.delegate = self;
    }
    return _poiPickerViewController;
}

- (ACCTagsCommodityPickerViewController *)commodityPickerViewController
{
    if (!_commodityPickerViewController) {
        _commodityPickerViewController = [[ACCTagsCommodityPickerViewController alloc] init];
        _commodityPickerViewController.delegate = self;
    }
    return _commodityPickerViewController;
}

- (ACCTagsCustomizeViewController *)customTagsViewController
{
    if (!_customTagsViewController) {
        _customTagsViewController = [[ACCTagsCustomizeViewController alloc] init];
        _customTagsViewController.delegate = self;
    }
    return _customTagsViewController;
}

- (void)setOriginalTag:(AWEInteractionEditTagStickerModel *)originalTag
{
    _originalTag = originalTag;
    if (!originalTag) {
        return ;
    }
    
    ACCTagsItemPickerViewController *itemPicker = [[self viewControllers] firstObject];
    NSString *tagID = nil;
    switch (originalTag.editTagInfo.type) {
        case ACCEditTagTypeUser:{
            itemPicker = self.userPickerViewController;
            tagID = originalTag.editTagInfo.userTag.userID;
        }
            break;
        case ACCEditTagTypePOI: {
            itemPicker = self.poiPickerViewController;
            tagID = originalTag.editTagInfo.POITag.POIID;
        }
            break;
        case ACCEditTagTypeCommodity: {
            itemPicker = self.commodityPickerViewController;
            tagID = originalTag.editTagInfo.goodsTag.productID;
        }
            break;
        case ACCEditTagTypeSelfDefine: {
            itemPicker = self.customTagsViewController;
            tagID = originalTag.editTagInfo.customTag.name;
        }
            break;
        default:
            break;
    }
    self.startTakingTabActions = NO;
    self.slidingViewController.selectedIndex = [[self viewControllers] indexOfObject:itemPicker];
    self.startTakingTabActions = YES;
    [itemPicker scrollToItem:tagID];
}

- (void)setBaseTrackerParams:(NSDictionary *)baseTrackerParams
{
    _baseTrackerParams = baseTrackerParams;
    self.userPickerViewController.trackerParams = baseTrackerParams;
    self.commodityPickerViewController.trackerParams = baseTrackerParams;
    self.poiPickerViewController.trackerParams = baseTrackerParams;
    self.customTagsViewController.trackerParams = baseTrackerParams;
}

- (NSTimeInterval)animationDuration
{
    return 0.5;
}

@end
