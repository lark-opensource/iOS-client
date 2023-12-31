//
//  TMAVideoFullScreenViewController.m
//  OPPluginBiz
//
//  Created by tujinqiu on 2019/11/5.
//

#import "TMAVideoFullScreenViewController.h"
#import "OPVideoFullScreenEdgeSwipeTransition.h"
#import <Masonry/Masonry.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPDeviceManager.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <ECOInfra/EMAFeatureGating.h>

@interface TMAVideoFullScreenViewController ()<UIViewControllerTransitioningDelegate>

@property (nonatomic, assign) UIInterfaceOrientation orientation;
@property (nonatomic, assign) CGRect initFrame;
@property (nonatomic, assign) BOOL useRotateScreenOldAPI;
@property (nonatomic, strong) OPVideoFullScreenEdgeSwipeTransition *swipeTransition;

@end

@implementation TMAVideoFullScreenViewController

- (instancetype)initWithTragetView:(TMAPlayerView *)targetView
                       orientation:(UIInterfaceOrientation)orientation
                 dismissCompletion:(dispatch_block_t)dismissCompletion
{
    if (self = [super init]) {
        _targetView = targetView;
        _orientation = orientation;
        _useRotateScreenOldAPI = [EMAFeatureGating boolValueForKey:@"openplatform.api.rotatenewapi.disable"];
        _swipeTransition = [[OPVideoFullScreenEdgeSwipeTransition alloc] initWithVC:self dismissCompletion:dismissCompletion];
        BDPLogInfo(@"TMAVideoFullScreenViewController init");
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.transitioningDelegate = self;
    self.view.backgroundColor = [UIColor blackColor];

    CGRect rect = [self.targetView convertRect:self.targetView.bounds toView:self.view];
    self.initFrame = rect;
    [self.view addSubview:self.targetView];
    [self.targetView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(rect.origin.x);
        make.top.equalTo(self.view).offset(rect.origin.y);
        make.size.mas_equalTo(rect.size);
    }];
    [self.targetView layoutIfNeeded];
    BDPLogInfo(@"TMAVideoFullScreenViewController viewDidLoad");
}

- (void)enter
{
    BDPLogInfo(@"TMAVideoFullScreenViewController enter");
    [self setInterfaceOrientation:self.orientation];
    [self.targetView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    if (self.orientation == UIInterfaceOrientationPortrait) {
        [UIView animateWithDuration:0.15 animations:^{
            [self.targetView layoutIfNeeded];
        }];
    }
}

- (void)exitWithCompletion:(dispatch_block_t)completion
{
    BDPLogInfo(@"TMAVideoFullScreenViewController exitWithCompletion");
    if (self.orientation != UIInterfaceOrientationPortrait) {
        [self setInterfaceOrientation:UIInterfaceOrientationPortrait];
    }
    [self.targetView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(self.initFrame.origin.x);
        make.top.equalTo(self.view).offset(self.initFrame.origin.y);
        make.size.mas_equalTo(self.initFrame.size);
    }];
    if (self.orientation != UIInterfaceOrientationPortrait) {
        [self.targetView layoutIfNeeded];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:completion];
        });
    } else {
        [UIView animateWithDuration:0.05 animations:^{
            [self.targetView layoutIfNeeded];
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:NO completion:completion];
        });
    }
}

- (void)setInterfaceOrientation:(UIInterfaceOrientation)orientation {
    BDPLogInfo(@"TMAVideoFullScreenViewController forcely set (device)Orientation to %@", @(orientation));

#ifdef __IPHONE_16_0
    // XCode14以上版本编译器使用如下代码
    if (@available (iOS 16, *)) {
        // iOS16以上设备使用新方法设置方向
        if (self.useRotateScreenOldAPI) {
            BDPLogInfo(@"useRotateScreenOldAPI");
            [BDPDeviceManager deprecated_deviceInterfaceOrientationAdaptTo:orientation];
        } else {
            BOOL hasFound = NO;
            for (UIScene* scene in UIApplication.sharedApplication.connectedScenes) {
                if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:UIWindowScene.self]) {
                    UIWindowScene *windowScene = (UIWindowScene *)scene;
                    UIInterfaceOrientationMask interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
                    switch (orientation) {
                        case UIInterfaceOrientationLandscapeLeft:
                            interfaceOrientationMask = UIInterfaceOrientationMaskLandscapeLeft;
                            break;
                        case UIInterfaceOrientationPortrait:
                            interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
                            break;
                        case UIInterfaceOrientationLandscapeRight:
                            interfaceOrientationMask = UIInterfaceOrientationMaskLandscapeRight;
                            break;
                        default:
                            interfaceOrientationMask = UIInterfaceOrientationMaskPortrait;
                            break;
                    }
                    UIWindowSceneGeometryPreferencesIOS *geometryPreferences = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:interfaceOrientationMask];
                    [windowScene requestGeometryUpdateWithPreferences:geometryPreferences errorHandler:^(NSError * _Nonnull error) {
                        // iOS16 新版强制转屏方法设置出错
                        BDPLogError(@"After iOS16, TMAVideoFullScreenViewController device forceRotateOrientation requestGeometryUpdate failed!");
                        return;
                    }];
                    BDPLogInfo(@"After iOS16, TMAVideoFullScreenViewController device forcely rotate to %@ succeed!", @(orientation));
                    hasFound = YES;
                }
            }
            if (!hasFound) {
                // iOS16 新版搜索当前活跃UIWindowScene失败
                BDPLogError(@"After iOS16, TMAVideoFullScreenViewController find UIWindowScene failed!");
            }
        }
    } else {
        // Xcode14 && iOS16以下设备使用旧方法设置方向
        [BDPDeviceManager deprecated_deviceInterfaceOrientationAdaptTo:orientation];
    }
#else
    // XCode14以下版本编译器使用旧方法设置方向
    [BDPDeviceManager deprecated_deviceInterfaceOrientationAdaptTo:orientation];
#endif
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    return self.swipeTransition;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id<UIViewControllerAnimatedTransitioning>)animator {
    if ([animator isKindOfClass:[OPVideoFullScreenEdgeSwipeTransition class]]) {
        OPVideoFullScreenInteractiveTranstion *transition = ((OPVideoFullScreenEdgeSwipeTransition *)animator).interactiveTransition;
        return transition.isInteracting ? transition : nil;
    }
    return nil;
}

@end
