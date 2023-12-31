//
//  BytedCertPopView.m
//
//  Created by LiuChundian on 2019/9/26.
//

#import "BDCTWebViewController.h"
#import "UIImage+BDCTAdditions.h"
#import "BytedCertUIConfig.h"
#import "BDCTAdditions.h"
#import <Masonry/Masonry.h>
#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <ByteDanceKit/ByteDanceKit.h>


@interface BDCTWebViewController () <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, copy) NSString *url;

@property (nonatomic, strong) UILabel *titleLabel;

@end


@implementation BDCTWebViewController

- (instancetype)initWithUrl:(NSString *)url title:(NSString *)title {
    self = [super init];
    if (self) {
        _url = url;
        self.title = title;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = BytedCertUIConfig.sharedInstance.backgroundColor;

    UIButton *navBackBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [navBackBtn setImage:[BytedCertUIConfig.sharedInstance.backBtnImage btd_ImageWithTintColor:BytedCertUIConfig.sharedInstance.textColor] forState:UIControlStateNormal];
    @weakify(self);
    [navBackBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton *_Nonnull sender) {
        @strongify(self);
        [self bdct_dismiss];
    }];
    [self.view addSubview:navBackBtn];
    [navBackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).offset(10);
        make.size.mas_equalTo(CGSizeMake(44, 44));
        if (@available(iOS 11.0, *)) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        } else {
            make.top.equalTo(self.view).offset(UIApplication.sharedApplication.statusBarFrame.size.height);
        }
    }];

    UILabel *titleLabel = [UILabel new];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.text = self.title;
    titleLabel.textColor = BytedCertUIConfig.sharedInstance.textColor;
    titleLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.height.equalTo(navBackBtn);
        make.width.equalTo(self.view).offset(-60 * 2);
        make.centerX.equalTo(self.view);
    }];
    self.titleLabel = titleLabel;

    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    webView.navigationDelegate = self;
    webView.UIDelegate = self;
    webView.opaque = NO;
    webView.backgroundColor = BytedCertUIConfig.sharedInstance.backgroundColor;
    webView.scrollView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:webView];
    [webView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(navBackBtn.mas_bottom);
    }];

    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL btd_URLWithString:self.url]]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.navigationController && [self.navigationController isKindOfClass:NSClassFromString(@"TTNavigationController")]) {
        [self.navigationController setNavigationBarHidden:YES animated:NO];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    btd_dispatch_async_on_main_queue(^{
        self.titleLabel.text = webView.title;
    });
}

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController pushViewController:[[BDCTWebViewController alloc] initWithUrl:navigationAction.request.URL.absoluteString title:nil] animated:YES];
    });
    return nil;
}

@end
