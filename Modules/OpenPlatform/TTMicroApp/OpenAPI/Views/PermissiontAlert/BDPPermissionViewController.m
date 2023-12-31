//
//  BDPPermissionViewController.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/13.
//

#import "BDPPermissionViewController.h"
#import <OPFoundation/BDPApplicationManager.h>
#import <OPFoundation/BDPAuthorization+BDPUtils.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPI18n.h>
#import "BDPListPermissionContentView.h"
#import "BDPMessagePermissoinContentView.h"
#import <OPFoundation/BDPNetworking.h>
#import "BDPPermissionView.h"
#import "BDPPhoneNumberPermissionContentView.h"
#import <OPFoundation/BDPScopeConfig.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPUserInfoManager.h>
#import <OPFoundation/BDPUtils.h>
#import "BDPWebAppEngine.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/EEFeatureGating.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>

static const CGFloat kLandscapeViewMaxWidth = 375.f;

@interface BDPPermissionViewController () <
UIViewControllerTransitioningDelegate,
UIGestureRecognizerDelegate,
BDPPermissionViewDelegate,
BDPListPermissionContentViewDelegate
>

@property (nonatomic, strong) OPAppUniqueID *uniqueID;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary *> *innerScopes;
@property (nonatomic, copy) NSArray<NSNumber *> *scopeList;
@property (nonatomic, copy) NSDictionary<NSString *, NSDictionary<NSString *, NSString *> *> *authorizeDescription;

@property (nonatomic, copy) NSString *phoneNumber;
@property (nonatomic, copy) NSDictionary *userInfo;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NSLayoutConstraint *permissionViewTopConstraint;
@property (nonatomic, strong) NSLayoutConstraint *permissionViewBottomConstraint;
@property (nonatomic, strong) BDPPermissionView *permissionView;
@property (nonatomic, strong) UIView *bottomSafeAreaBackgroundView;
@property (nonatomic, assign) BOOL enableNewStyle;

- (void)makePermissionViewUnderScreen;
- (void)makePermissionViewOverScreen;

@end

@interface BDPPermissionViewControllerPresentAnimation : NSObject<UIViewControllerAnimatedTransitioning>

@end

@implementation BDPPermissionViewControllerPresentAnimation


- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return .45f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    BDPPermissionViewController *controller = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [[transitionContext containerView] addSubview:controller.view];
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    controller.view.backgroundColor = [UIColor clearColor];

    [controller makePermissionViewUnderScreen];
    [controller.view layoutIfNeeded];
    
    CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithControlPoints:0.22 :1 :0.36 :1];
    [UIView beginAnimations:nil context:NULL];
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    [CATransaction setAnimationTimingFunction:function];
    [CATransaction setCompletionBlock:^{
        [transitionContext completeTransition:YES];
    }];
    
    //do animate
    controller.view.backgroundColor = UIColor.bdp_BlackColor4;
    [controller makePermissionViewOverScreen];
    [controller.view layoutIfNeeded];
    
    [CATransaction commit];
    [UIView commitAnimations];
}

@end

@interface BDPPermissionViewControllerDismissAnimation : NSObject<UIViewControllerAnimatedTransitioning>

@end

@implementation BDPPermissionViewControllerDismissAnimation

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return .24f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    BDPPermissionViewController *controller = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    CAMediaTimingFunction *function = [CAMediaTimingFunction functionWithControlPoints:0.39 :0.575 :0.565 :1];
    [UIView beginAnimations:nil context:NULL];
    [CATransaction begin];
    [CATransaction setAnimationDuration:duration];
    [CATransaction setAnimationTimingFunction:function];
    [CATransaction setCompletionBlock:^{
        [controller.view removeFromSuperview];
        [transitionContext completeTransition:YES];
    }];
    
    //do animations
    controller.view.backgroundColor = UIColor.clearColor;
    [controller makePermissionViewUnderScreen];
    [controller.view layoutIfNeeded];

    [CATransaction commit];
    [UIView commitAnimations];
}

@end

@implementation BDPPermissionViewController

// Don't Call this Method, just for: BDPBasePluginDelegate.h
+ (id<BDPPermissionViewControllerDelegate>)sharedPlugin {
    return [[BDPPermissionViewController alloc] initWithName:@"" icon:nil uniqueID:nil authScopes:nil scopeList:nil];
}

+ (UIViewController<BDPPermissionViewControllerDelegate> *)initControllerWithName:(NSString *)name
                        icon:(NSString *)icon
                    uniqueID:(OPAppUniqueID *)uniqueID
                  authScopes:(NSDictionary<NSString *, NSDictionary *> *)authScopes
                   scopeList:(NSArray<NSNumber *> *)scopeList {
    return [[self alloc] initWithName:name icon:icon uniqueID:uniqueID authScopes:authScopes scopeList:scopeList];
}

#pragma mark - init

- (instancetype)initWithName:(NSString *)name
                        icon:(NSString *)icon
                    uniqueID:(OPAppUniqueID *)uniqueID
                  authScopes:(NSDictionary<NSString *, NSDictionary *> *)authScopes
                   scopeList:(NSArray<NSNumber *> *)scopeList
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _appName = name.copy;
        _icon = icon.copy;
        _uniqueID = uniqueID;
        _innerScopes = authScopes.copy;
        _scopeList = scopeList.copy;
        _enableNewStyle = YES;
#if DEBUG
//        _enableNewStyle = YES;
#endif
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.transitioningDelegate = self;
    }
    return self;
}

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

#pragma mark - Utils

- (NSString *)scopeTitleForScope:(BDPPermissionScopeType)scopeType
{
    NSString *title = [self hostScopeTitleForScope:scopeType];
    if (!title) {
       title = [self innerScopeTitleForScope:scopeType];
    }
    
    return title;
}

- (NSString *)scopeDescriptionForScope:(BDPPermissionScopeType)scopeType
{
    NSString *description = nil;
    NSDictionary<NSString *, NSString *> *entity = nil;
    switch (scopeType) {
        case BDPPermissionScopeTypeAlbum:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeAlbum];
            break;
        case BDPPermissionScopeTypeCamera:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeCamera];
            break;
        case BDPPermissionScopeTypeAddress:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeAddress];
            break;
        case BDPPermissionScopeTypeLocation:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeUserLocation];
            break;
        case BDPPermissionScopeTypeMicrophone:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeRecord];
            break;
        case BDPPermissionScopeTypeScreenRecord:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeScreenRecord];
            break;
        case BDPPermissionScopeTypeClipboard:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeClipboard];
            break;
        case BDPPermissionScopeTypeAppBadge:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeAppBadge];
            break;
        case BDPPermissionScopeTypeRunData:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeRunData];
            break;
        case BDPPermissionScopeTypeBluetooth:
            entity = [self.authorizeDescription bdp_dictionaryValueForKey:BDPScopeBluetooth];
            break;
        case BDPPermissionScopeTypeUserInfo:
        case BDPPermissionScopeTypePhoneNumber:
        case BDPPermissionScopeTypeUnknown:
            break;
    }
    
    description = [entity bdp_stringValueForKey:@"desc"];
    if (!description.length) {
        description = [self innerScopeDescriptionForScope:scopeType];
    }
    
    // 临时先加长文案的截断范围 让getuserinfo的授权弹窗文案完整显示
    if([EMAFeatureGating boolValueForKey: EEFeatureGatingKeyGetAddAuthTextLength]){
        description = [description bdp_subStringForMaxWordLength:40.f withBreak:YES];
    } else {
        description = [description bdp_subStringForMaxWordLength:24.f withBreak:YES];
    }
    
    return description;
}

- (NSString *)hostScopeTitleForScope:(BDPPermissionScopeType)scopeType
{
    NSString *title = nil;
    BDPScopeConfig *config = [BDPTimorClient sharedClient].currentNativeGlobalConfiguration.scopeConfig;
    switch (scopeType) {
        case BDPPermissionScopeTypeUserInfo:
            title = config.userInfo.scopeName;
            break;
        case BDPPermissionScopeTypeAlbum:
            title = config.album.scopeName;
            break;
        case BDPPermissionScopeTypeCamera:
            title = config.camera.scopeName;
            break;
        case BDPPermissionScopeTypeAddress:
            title = config.address.scopeName;
            break;
        case BDPPermissionScopeTypeLocation:
            title = config.location.scopeName;
            break;
        case BDPPermissionScopeTypeMicrophone:
            title = config.microphone.scopeName;
            break;
        case BDPPermissionScopeTypePhoneNumber:
            title = config.phoneNumber.scopeName;
            break;
        case BDPPermissionScopeTypeClipboard:
            title = config.clipboard.scopeName;
            break;
        case BDPPermissionScopeTypeAppBadge:
            title = config.appBadge.scopeName;
            break;
        case BDPPermissionScopeTypeRunData:
            title = config.appBadge.scopeName;
            break;
        case BDPPermissionScopeTypeBluetooth:
        case BDPPermissionScopeTypeUnknown:
        case BDPPermissionScopeTypeScreenRecord:
        default:
            break;
    }
    
    return title;
}

- (NSString *)innerScopeTitleForScope:(BDPPermissionScopeType)scopeType
{
    NSDictionary *entity = [self innerScopeEntityForScopeType:scopeType];
    
    NSString *title = [entity bdp_stringValueForKey:@"title"];
    
    return title;
}

- (NSString *)innerScopeDescriptionForScope:(BDPPermissionScopeType)scopeType
{
    NSDictionary *entity = [self innerScopeEntityForScopeType:scopeType];
    NSString *description = [entity bdp_stringValueForKey:@"description_new"];
    NSDictionary *applicationInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *applicationName = [applicationInfo bdp_stringValueForKey:@"CFBundleDisplayName"]?:@"";
    NSString *hostNamePlaceHolder = @"{host_name}";
    description = [description stringByReplacingOccurrencesOfString:hostNamePlaceHolder withString:applicationName];

    return description;
}

- (NSDictionary *)innerScopeEntityForScopeType:(BDPPermissionScopeType)scopeType
{
    NSString *innerScope = [BDPAuthorization transfromScopeTypeToInnerScope:scopeType];
    NSDictionary *entity = nil;
    if (innerScope) {
        entity = [self.innerScopes bdp_dictionaryValueForKey:innerScope];
    }
    
    return entity;
}

- (UIView *)permissionContentViewForScopeList:(NSArray<NSNumber *> *)scopeList
{
    if (scopeList.count == 0) {
        return nil;
    }
    
    if (scopeList.count == 1) {
        return [self permissionContentViewForScope:scopeList.firstObject.integerValue];
    }
    
    NSMutableArray<NSString *> *titleList = [NSMutableArray array];
    [scopeList enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *title = [self scopeTitleForScope:obj.integerValue];
        if (title) {
            [titleList addObject:title];
        }
    }];
    
    BDPListPermissionContentView *contentView = [[BDPListPermissionContentView alloc] initWithTitleList:titleList.copy isNewStyle:self.enableNewStyle];
    contentView.delegate = self;
    return contentView;
}

- (UIView *)permissionContentViewForScope:(BDPPermissionScopeType)scopeType
{
    UIView *contentView = nil;
    NSString *scopeTitle = [self scopeTitleForScope:scopeType];
    NSString *scopeDescription = [self scopeDescriptionForScope:scopeType];
    switch (scopeType) {
        case BDPPermissionScopeTypeMicrophone:
        case BDPPermissionScopeTypeAlbum:
        case BDPPermissionScopeTypeCamera:
        case BDPPermissionScopeTypeLocation:
        case BDPPermissionScopeTypeAddress:
        case BDPPermissionScopeTypeClipboard:
        case BDPPermissionScopeTypeScreenRecord:
        case BDPPermissionScopeTypeAppBadge:
        // 5.1版 getUserInfo授权弹窗(只需要文字描述)
        case BDPPermissionScopeTypeUserInfo:
        case BDPPermissionScopeTypeBluetooth:
        case BDPPermissionScopeTypeRunData:
            contentView = [[BDPMessagePermissoinContentView alloc] initWithTitle:scopeTitle message:scopeDescription isNewStyle:self.enableNewStyle];
            break;
        case BDPPermissionScopeTypePhoneNumber:
            contentView = [[BDPPhoneNumberPermissionContentView alloc] initWithFrame:CGRectZero window:self.view.window];
            [self flatePhoneNumberContentView:(BDPPhoneNumberPermissionContentView *)contentView];
            break;
        case BDPPermissionScopeTypeUnknown:
            break;
    }
    return contentView;
}

//- (void)flateUserInfoContentView:(BDPUserInfoPermissionContentView *)contentView
//{
//    if (![contentView isKindOfClass:BDPUserInfoPermissionContentView.class]) {
//        return;
//    }
//
//    WeakSelf;
//    void (^blk)(NSDictionary *data, NSError *error) = nil;
//    blk = ^(NSDictionary * _Nonnull data, NSError * _Nonnull error) {
//        StrongSelfIfNilReturn;
//        if (error) {
//            return;
//        }
//
//        if (!data.count) {
//            return;
//        }
//
//        NSDictionary *userInfo = [data bdp_dictionaryValueForKey:BDPUserInfoUserInfoKey];
//        NSString *avatarURL = [userInfo bdp_stringValueForKey:BDPUserInfoAvatarURLKey];
//        NSString *nickName = [userInfo bdp_stringValueForKey:BDPUserInfoNickNameKey];
//
//        if (avatarURL.length) {
//            [BDPNetworking setImageView:contentView.userIconView url:[NSURL URLWithString:avatarURL] placeholder:nil];
//        }
//        contentView.userNameLabel.text = nickName;
//        contentView.titleLabel.text = [self scopeTitleForScope:BDPPermissionScopeTypeUserInfo];
//    };
//
//    if (self.userInfo.count) {
//        blk(self.userInfo, nil);
//    }
//    BDPAppContext *context = [[BDPAppContext alloc] init];
//    context.controller = self.engine.bridgeController;
//    context.engine = self.engine;
//
//    [BDPUserInfoManager fetchUserInfoWithCredentials:NO context:context completion:blk];
//}

- (void)flatePhoneNumberContentView:(BDPPhoneNumberPermissionContentView *)contentView
{
    if (!contentView) {
        return;
    }
    
    NSString *title = [self scopeTitleForScope:BDPPermissionScopeTypePhoneNumber];
    if (title.length) {
        contentView.titleLabel.text = title;
    } else {
        NSDictionary *applicationInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *applicationName = [applicationInfo bdp_stringValueForKey:@"CFBundleDisplayName"]?:@"";
        title = [NSString stringWithFormat:BDPI18n.bind_phone_number, applicationName];
        contentView.titleLabel.text = title;
    }
    [contentView setPhoneNumer:self.phoneNumber];
}

#pragma mark - UI

_Pragma("clang diagnostic push")
_Pragma("clang diagnostic ignored \"-Wunguarded-availability\"")


- (void)setupUI
{
    [self setupContainer];
    [self setupPermissionView];
}

- (void)setupContainer
{
    UIView *containerView = [UIView new];
    containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:containerView];
    self.containerView = containerView;
    
    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onContainerTouched:)];
    tapGesture.delegate = self;
    [containerView addGestureRecognizer:tapGesture];

    [self.containerView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor].active = YES;
    
    [self.containerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    
    UIInterfaceOrientation status = [UIApplication sharedApplication].statusBarOrientation;
    
    BOOL isPortrait = UIInterfaceOrientationIsPortrait(status);
    if (isPortrait) {
        [self.containerView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
        [self.containerView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    } else {
        [self.containerView.widthAnchor constraintEqualToConstant:kLandscapeViewMaxWidth].active = YES;
        [self.containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor].active = YES;
    }
}

- (void)setupPermissionView
{
    NSString *actionDescption = [NSString stringWithFormat:BDPI18n.requesting_privacy, self.appName];
    if (BDPIsEmptyString(self.appName)) {
        actionDescption = BDPI18n.LittleApp_TTMicroApp_ApplyPrmssnIn;
    }
    NSString *scopeTitle = [self scopeTitleForScope:self.scopeList.firstObject.integerValue];
    UIView *contentView = [self permissionContentViewForScopeList:self.scopeList];
    BDPPermissionView *permissionView = [[BDPPermissionView alloc] initWithActionDescption:actionDescption
                                                                           permissionTitle:scopeTitle
                                                                                      logo:self.icon
                                                                               contentView:contentView
                                                                                   appName:self.appName
                                                                                  newStyle:self.enableNewStyle
                                                                                  uniqueID:self.uniqueID];
    permissionView.delegate = self;
    [self.containerView addSubview:permissionView];
    self.permissionView = permissionView;
    if(self.enableNewStyle) {
        permissionView.layer.cornerRadius = 8;
        permissionView.layer.masksToBounds = YES;
        [UDOCLayerBridge setShadowColorWithLayer:permissionView.layer color:UDOCColor.shadowDefaultSm];
        permissionView.layer.shadowOffset = CGSizeMake(5.0, 10.0);
    }
    
    [self makePermissionViewOverScreen];
}

- (void)makePermissionViewUnderScreen
{
    //remove all constraints which effect permissionView
    [self.permissionView removeFromSuperview];
    [self.containerView addSubview:self.permissionView];
    if(self.enableNewStyle) {
        [self.permissionView.leftAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leftAnchor constant:36.0].active = YES;
        [self.permissionView.rightAnchor constraintLessThanOrEqualToAnchor:self.containerView.rightAnchor constant:-36.0].active = YES;
        [self.permissionView.widthAnchor constraintLessThanOrEqualToConstant:375].active = YES;
        [self.permissionView.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor].active = YES;
        [self.permissionView.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor].active = YES;

    } else {
        [self.permissionView.leftAnchor constraintEqualToAnchor:self.containerView.leftAnchor].active = YES;
        [self.permissionView.rightAnchor constraintEqualToAnchor:self.containerView.rightAnchor].active = YES;
        [self.permissionView.topAnchor constraintEqualToAnchor:self.containerView.bottomAnchor].active = YES;
    }
    [self.containerView layoutIfNeeded];
}

- (void)makePermissionViewOverScreen
{
    //remove all constraints which effect permissionView
    [self.permissionView removeFromSuperview];
    [self.containerView addSubview:self.permissionView];
    if(self.enableNewStyle) {
        [self.permissionView.leftAnchor constraintGreaterThanOrEqualToAnchor:self.containerView.leftAnchor constant:36.0].active = YES;
        [self.permissionView.rightAnchor constraintLessThanOrEqualToAnchor:self.containerView.rightAnchor constant:-36.0].active = YES;
        [self.permissionView.widthAnchor constraintLessThanOrEqualToConstant:375].active = YES;
        [self.permissionView.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor].active = YES;
        [self.permissionView.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor].active = YES;
    } else {
        [self.permissionView.leftAnchor constraintEqualToAnchor:self.containerView.leftAnchor].active = YES;
        [self.permissionView.rightAnchor constraintEqualToAnchor:self.containerView.rightAnchor].active = YES;
        [self.permissionView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor].active = YES;
    }
    [self.containerView layoutIfNeeded];
}
_Pragma("clang diagnostic pop")

#pragma mark - Action

- (void)onContainerTouched:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (touch.view != self.view) {
        return NO;
    }
    
    return YES;
}

#pragma mark - BDPPermissionViewController Delegate

- (NSArray<NSNumber *> *)authorizedScopeList
{
    NSArray<NSNumber *> *authorizedScopeList = nil;
    if ([self.permissionView.contentView isKindOfClass:BDPListPermissionContentView.class]) {
        BDPListPermissionContentView *listPermissionView = (BDPListPermissionContentView *)self.permissionView.contentView;
        NSArray<NSNumber *> *selectedScopes = [listPermissionView selectedIndexs];
        NSMutableArray<NSNumber *> *list = [NSMutableArray array];
        [selectedScopes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger index = obj.integerValue;
            if (index < self.scopeList.count) {
                [list addObject:self.scopeList[index]];
            }
        }];
        authorizedScopeList = list.copy;
    } else {
        //如果不是多选的， 那必然是同意了的
        authorizedScopeList = self.scopeList;
    }
    
    return authorizedScopeList;
}

- (NSArray<NSNumber *> *)deniedScopeList
{
    NSArray<NSNumber *> *deniedScopeList = nil;
    if ([self.permissionView.contentView isKindOfClass:BDPListPermissionContentView.class]) {
        BDPListPermissionContentView *listPermissionView = (BDPListPermissionContentView *)self.permissionView.contentView;
        NSArray<NSNumber *> *selectedScopes = [listPermissionView selectedIndexs];
        
        NSMutableArray<NSNumber *> *marks = [NSMutableArray arrayWithCapacity:self.scopeList.count];
        [self.scopeList enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [marks addObject:@(NO)];
        }];
        [selectedScopes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSInteger index = obj.integerValue;
            if (index < marks.count) {
                marks[index] = @(YES);
            }
        }];
        NSMutableArray<NSNumber *> *list = [NSMutableArray array];
        [marks enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            BOOL selected = obj.boolValue;
            if (!selected && idx < self.scopeList.count) {
                [list addObject:self.scopeList[idx]];
            }
        }];
        deniedScopeList = list.copy;
    } else {
        deniedScopeList = [NSArray array];
    }
    
    return deniedScopeList;
}

- (void)permissionViewDidConfirm:(BDPPermissionView *)permissionView
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            NSArray<NSNumber *> *authorizedList = [self authorizedScopeList];
            NSArray<NSNumber *> *deniedList = [self deniedScopeList];
            self.completion(authorizedList, deniedList);
        }
    }];
}

- (void)permissionViewDidCancel:(BDPPermissionView *)permissionView
{
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            self.completion([NSArray new], self.scopeList);
        }
    }];
}

#pragma mark - Getter && Setter

- (NSDictionary<NSString *, NSDictionary *> *)innerScopes
{
    return _innerScopes.copy;
}

- (NSDictionary<NSString *, NSString *> *)authorizeDescription
{
    if (!_authorizeDescription) {
        BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
        _authorizeDescription = task.config.permission;
    }
    
    return _authorizeDescription.copy;
}

#pragma mark - Custom Transition

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
                                                                  presentingController:(UIViewController *)presenting
                                                                      sourceController:(UIViewController *)source {
    return [BDPPermissionViewControllerPresentAnimation new];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [BDPPermissionViewControllerDismissAnimation new];
}

#pragma mark - BDPListPermisionContentViewDelegate

- (void)contentView:(BDPListPermissionContentView *)contentView didUpdateSelectedIndexes:(NSArray<NSNumber *> *)selectedIndexs
{
    if (!selectedIndexs.count) {
        self.permissionView.confirmButton.enabled = NO;
        self.permissionView.confirmButton.alpha = 0.4;
    } else {
        self.permissionView.confirmButton.enabled = YES;
        self.permissionView.confirmButton.alpha = 1.f;
    }
}

#pragma mark - Override

- (BOOL)shouldAutorotate
{
    return NO;
}

@end
