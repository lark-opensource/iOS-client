//
//  EMABaseViewController.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/3.
//

#import "EMABaseViewController.h"
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPDeviceHelper.h>

BOOL EMA_STATUS_BAR_ORIENTATION_MODIFY = NO;

@interface EMABaseViewController () {
    UIStatusBarStyle _lastStyle;
}
@property(nonatomic, copy) EMAAppPageCompletionBlock completionBlock;
@end

@implementation EMABaseViewController

- (void)dealloc
{
    if (self.completionBlock) {
        self.completionBlock(self);
    }
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {

    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {

    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}


- (instancetype)initWithRouteParamObj:(TTRouteParamObj *)paramObj
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [self commonInit];
        self.completionBlock = [paramObj.userInfo.extra objectForKey:@"completion_block"];

    }
    return self;
}

- (void)commonInit {
    // could be extended
    self.hidesBottomBarWhenPushed = YES;
    self.viewBoundsChangedNotifyEnable = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)dismissSelf
{
    if (self.navigationController.viewControllers.count>1) {
        NSArray *viewControllers = self.navigationController.viewControllers;
        if (viewControllers && viewControllers.count > 1) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

#pragma mark -- rotate

- (BOOL)shouldAutorotate
{
    if ([BDPDeviceHelper isPadDevice]) {
        return YES;
    } else {
        // 如果需要手动设置status bar的方向，则shouldAutorotate必须返回NO
        if (EMA_STATUS_BAR_ORIENTATION_MODIFY) {
            return NO;
        } else {
            return YES;
        }
    }
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([BDPDeviceHelper isPadDevice]) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

@end

