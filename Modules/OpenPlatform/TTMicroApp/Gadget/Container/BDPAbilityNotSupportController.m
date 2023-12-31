//
//  BDPAbilityNotSupportController.m
//  Timor
//
//  Created by lilun.ios on 2020/9/15.
//

#import "BDPAbilityNotSupportController.h"
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/UIImage+BDPExtension.h>
#import <Masonry/Masonry-umbrella.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPAppLoadManager+Clean.h"
#import "BDPWarmBootManager.h"
#import "BDPTaskManager.h"
#import <OPFoundation/BDPResponderHelper.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPI18n.h>

#import <OPSDK/OPSDK-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

@interface BDPAbilityNotSupportController ()

@end

@implementation BDPAbilityNotSupportController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupViews];
    BDPLogInfo(@"BDPAbilityNotSupportController show ability %@ app %@", self.ability, self.uniqueID);
    self.navigationController.navigationBar.tintColor = UDOCColor.iconN1;
    self.navigationController.navigationBar.backgroundColor = UDOCColor.bgBody;
}

- (void)setupViews
{
    /// 页面背景色
    self.view.backgroundColor = UDOCColor.bgBody;
    /// 右上角关闭按钮
    UIImage *closeImage = [UIImage imageNamed:@"tma_navi_close" inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil];
    UIBarButtonItem *closeItem = [[UIBarButtonItem alloc] initWithImage:closeImage style:UIBarButtonItemStylePlain target:self action:@selector(closeButtonClicked:)];
    self.navigationItem.rightBarButtonItem = closeItem;
    /// 中间的icon 提示
    UIImage *image = [UIImage bdp_imageNamed:@"ability_notsupport"];
    UIImageView *imageview = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:imageview];
    CGSize size = CGSizeMake(150, 150);
    [imageview mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(size);
        make.centerX.mas_equalTo(self.view);
        make.top.mas_equalTo(self.view).offset((182.0 / 812.0 ) * self.view.frame.size.height);
    }];
    /// 中间的tips 提示
    UILabel *tipsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [tipsLabel setTextColor:UDOCColor.textCaption];
    [tipsLabel setText:[BDPI18n LittleApp_TTMicroApp_InputScVerUpdtMsg]];
    [tipsLabel setTextAlignment:NSTextAlignmentCenter];
    [tipsLabel setFont:[UIFont systemFontOfSize:14.0]];
    [tipsLabel setNumberOfLines:2];
    [self.view addSubview:tipsLabel];
    [tipsLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self.view);
        make.top.mas_equalTo(imageview.mas_bottom).offset(17.0);
        make.height.mas_greaterThanOrEqualTo(22);
    }];
    
    /// 取消按钮
    CGSize buttonSize = CGSizeMake(88, 36);
    UIButton *cancelButton = [self makeButton:YES];
    [self.view addSubview:cancelButton];
    [cancelButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self.view.mas_centerX).offset(-8);
        make.top.mas_equalTo(tipsLabel.mas_bottom).offset(32.0);
        make.size.mas_equalTo(buttonSize);
    }];
    [cancelButton setTitle:[BDPI18n LittleApp_TTMicroApp_InputScUpdtLaterBttn] forState:UIControlStateNormal];
    [cancelButton setTitleColor:UDOCColor.textTitle forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelClicked:) forControlEvents:UIControlEventTouchUpInside];
    /// 确认按钮
    UIButton *comfirmButton = [self makeButton:NO];
    [self.view addSubview:comfirmButton];
    [comfirmButton mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(self.view.mas_centerX).offset(8);
        make.top.mas_equalTo(tipsLabel.mas_bottom).offset(32.0);
        make.size.mas_equalTo(buttonSize);
    }];
    [comfirmButton setTitle:[BDPI18n LittleApp_TTMicroApp_InputScUpdtBttn] forState:UIControlStateNormal];
    [comfirmButton setTitleColor:UDOCColor.staticWhite forState:UIControlStateNormal];
    UIColor *backgroundColor = UDOCColor.primaryPri500;
    WeakObject(comfirmButton);
    [comfirmButton opSetDynamicWithHandler:^(UITraitCollection * _Nonnull collection) {
        StrongObject(comfirmButton);
        [comfirmButton setBackgroundImage:[UIImage bdp_imageWithUIColor:backgroundColor]
                                 forState:UIControlStateNormal];
    }];
    [comfirmButton addTarget:self action:@selector(comfirmClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (UIButton *)makeButton:(BOOL)hasOutline {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.layer.cornerRadius = 4;
    if (hasOutline) {
        WeakObject(button);
        [self.view opSetDynamicWithHandler:^(UITraitCollection * _Nonnull collection) {
            StrongObject(button);
            button.layer.borderColor = [UDOCColor.lineBorderComponent CGColor];
        }];
        button.layer.borderWidth = 1;
    }
    button.clipsToBounds = YES;
    return button;
}

- (void)closeButtonClicked:(UIButton *)sender {
    BDPLogInfo(@"closeButtonClicked %@", sender);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelClicked:(UIButton *)sender {
    BDPLogInfo(@"cancelClicked %@", sender);
    [self closeButtonClicked:nil];
}

- (void)comfirmClicked:(UIButton *)sender {
    BDPLogInfo(@"comfirmClicked %@", sender);
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:self.uniqueID];
    UIViewController<BDPlatformContainerProtocol> *containerVC = task.containerVC;
    UIWindow *window = self.view.window ?: OPWindowHelper.fincMainSceneWindow;
    // 干掉当前页面的presentVC，否则无法退出小程序
    [self dismissViewControllerAnimated:YES completion:^{
        UIViewController *topMost = [BDPResponderHelper topViewControllerForController:window.rootViewController fixForPopover:false];
        [[BDPWarmBootManager sharedManager] cleanCacheWithUniqueID:self.uniqueID];
        /// 删除当前小程序的进程
        NSString *pkgName = [[BDPCommonManager sharedManager] getCommonWithUniqueID:self.uniqueID].model.pkgName;
        if(pkgName.length > 0 ) {
            [[BDPAppLoadManager shareService] removeAllMetaAndDataWithUniqueID:self.uniqueID                                                                          pkgName:pkgName];
        }
        if (topMost == containerVC || containerVC.presentingViewController) {
            OPMonitorCode *code = GDMonitorCode.exit_app_ability_not_support;

            // unmount 只能简单退出小程序在栈顶的情况
            [[OPApplicationService.current getContainerWithUniuqeID:self.uniqueID] unmountWithMonitorCode:code];

            OPErrorNew(code, nil, @{@"ability": self.ability ?: @""});
        }
    }];
}
@end
