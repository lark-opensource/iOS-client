//
//  CJPaySimpleLoadingViewController.m
//  Aweme
//
//  Created by ByteDance on 2023/8/7.
//

#import "CJPaySimpleLoadingViewController.h"
#import "CJPayLoadingManager.h"
#import "UIColor+CJPay.h"

@implementation CJPaySimpleLoadingViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    //显示抖音支付Loading
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinOpenDeskLoading];
}

- (void)p_setupUI {
    self.navigationBar.hidden = YES;
    self.view.backgroundColor = [UIColor cj_393b44ff];
}

@end
