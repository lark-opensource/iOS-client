//
//  CJPayDataSecurityModel.m
//  Pods
//
//  Created by gh on 2021/9/9.
//

#import "CJPayDataSecurityModel.h"
#import "UIViewController+CJPay.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayUIMacro.h"
#import "CJPayBaseViewController.h"
#import "UIView+CJPay.h"

@interface CJPayDataSecurityModel()

@property (nonatomic, assign) BOOL isNeedDataSecurity;
@property (nonatomic, weak) UIViewController *sourceVC;
@property (nonatomic,weak) UIView *dimView;

@end

@implementation CJPayDataSecurityModel

+ (instancetype)shared
{
    static CJPayDataSecurityModel *dataSecurityModel;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dataSecurityModel = [[CJPayDataSecurityModel alloc] init];
    });
    return dataSecurityModel;
}

- (void)bindViewControllerToModel:(UIViewController *)vc {
    self.isNeedDataSecurity = [CJPaySettingsManager shared].currentSettings.enableDataSecurity.enableDataSecurity;
    if(self.sourceVC == nil) {
        self.sourceVC = vc;
    }
}

- (void)p_bindDimView:(UIView *)dimVC {
    if(self.dimView) {
        [self.dimView removeFromSuperview];
        self.dimView = nil;
    }
    if(dimVC && (dimVC.tag == 951213)) {
        self.dimView = dimVC;
    }
}

- (void)p_clearDimView {
    if(self.dimView) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.dimView.alpha = 0;
            } completion:^(BOOL finished) {
                [self.dimView removeFromSuperview];
                self.dimView = nil;
            }];
    }
}

- (void)setIsNeedDataSecurity:(BOOL)need {
    if(_isNeedDataSecurity == need) {
        return;
    }
    _isNeedDataSecurity = need;
    if(need) {
        if(@available(iOS 13.0, *)) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_addBlurview:)
                                                         name:UISceneDidEnterBackgroundNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_clearBlurView:)
                                                         name:UISceneDidActivateNotification
                                                       object:nil];
        }
        else {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_addBlurview:)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_clearBlurView:)
                                                         name:UIApplicationDidBecomeActiveNotification
                                                       object:nil];
        }
    }
}

- (void)p_addBlurview:(NSNotification *)aNotification {
    if (!self.sourceVC) {
        return;
    }
    if ([CJPaySettingsManager shared].currentSettings.enableDataSecurity.blurType) {
        [self p_blurV2:self.sourceVC];
    } else {
        [self p_blurImage:self.sourceVC];
    }
}
    

- (void)p_clearBlurView:(NSNotification *)aNotification {
    [self p_clearDimView];
}

- (void)p_blurImage:(UIViewController *)sourceVC {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:sourceVC];
    if(![self cj_hasCJPayVC:vc]) {
        return;
    }
    UIImage *showImage = [vc.view.window cjpay_snapShotImage];
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputimage = [[CIImage alloc]initWithImage:showImage];
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur" keysAndValues:@"inputImage", inputimage,@"inputRadius",@13.f,nil];
    CIImage *result = filter.outputImage;
    CGImageRef cgimg = [context createCGImage:result fromRect:[inputimage extent]];
    UIImage *r = [UIImage imageWithCGImage:cgimg scale:showImage.scale orientation:showImage.imageOrientation];
    CGImageRelease(cgimg);
    if (@available(iOS 10.0, *)) {
        [context clearCaches];
    } else {
        // Fallback on earlier versions
    }
    UIImageView *dimView = [[UIImageView alloc]initWithImage:r];
    dimView.tag = 951213;
    if(vc.view.window == nil) {
        return;
    }
    [vc.view.window addSubview:dimView];
    CJPayMasMaker(dimView, {
        make.edges.equalTo(vc.view.window);
    });
    [self p_bindDimView:dimView];
    return;
}

- (void)p_blurV2:(UIViewController *)sourceVC {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:sourceVC];
    if(![self cj_hasCJPayVC:vc]) {
        return;
    }
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    if(vc.view.window == nil) {
        return;
    }
    visualView.tag = 951213;
    [vc.view.window addSubview:visualView];
    CJPayMasMaker(visualView, {
        make.edges.equalTo(vc.view.window);
    });
    [self p_bindDimView:visualView];
}

- (BOOL)cj_hasCJPayVC:(UIViewController *)vc {
    if (vc == nil){
        return NO;
    }
    if ([vc isKindOfClass:[CJPayBaseViewController class]]) {
        return YES;
    } else {
        while(vc.presentingViewController) {
            vc = vc.presentingViewController;
            if ([vc isKindOfClass:[CJPayBaseViewController class]] || [vc isKindOfClass:[CJPayNavigationController class]]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
