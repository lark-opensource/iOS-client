//
//  ADFeelGoodTestViewController.m
//  FeelGoodDemo
//
//  Created by bytedance on 2020/8/25.
//  Copyright © 2020 huangyuanqing. All rights reserved.
//

#import "ADFeelGoodViewController.h"
#import "ADFGWebViewBridgeEngine.h"
#import "ADFeelGoodBridgeNameDefines.h"
#import "ADFGCommonMacros.h"
#import "ADFGLoadResource.h"
#import "ADFeelGoodConfig.h"
#import "ADFeelGoodOpenModel.h"
#import "ADFeelGoodOpenModel+Private.h"
#import "ADFeelGoodInfo.h"
#import "ADFeelGoodInfo+Private.h"
#import "ADFGUtils.h"

NSString const* FGRCCompactModel = @"compact";
NSString const* FGRCRegularModel = @"regular";

@interface ADFeelGoodViewController ()<ADFGWKWebViewDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) ADFeedGoodLoadStatusView *statusView;
@property (nonatomic, strong) ADFGWKWebView *webView;
@property (nonatomic, strong) ADFeelGoodOpenModel *openModel;

@end

@implementation ADFeelGoodViewController

static BOOL enableOpen = YES;

- (void)dealloc
{
//    enableOpen = YES;
}

- (instancetype)initWithOpenModel:(ADFeelGoodOpenModel *)openModel
{
    if (!enableOpen) {
        return nil;
    }
    enableOpen = NO;
    if (self = [super init]) {
        _openModel = openModel;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.webView];
    [self startRequset];
    if (self.openModel.needLoading) {
        self.view.hidden = NO;
    } else {
        self.view.hidden = YES;
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.webView.frame = self.view.bounds;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma RC change
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection
                    withTransitionCoordinator:coordinator];
    [self fetchViewTraitCollectionSizeClass:newCollection];
}

- (void)fetchViewTraitCollectionSizeClass:(UITraitCollection *)collection
{
    NSString *FGRCModel = @"";
    if (collection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        FGRCModel = FGRCCompactModel;
    } else {
        FGRCModel = FGRCRegularModel;
    }
    [self.webView.adfg_engine fireEvent:ADFGiPadLayoutChangeIFNeed params:@{@"mode":FGRCModel} resultBlock:nil];
}

- (void)prepareiPadLayoutModeParams
{
    NSString *FGRCModel = @"";
    FGRCModel = self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact ? FGRCCompactModel : FGRCRegularModel;
    NSMutableDictionary *mutdict = [[NSMutableDictionary alloc] initWithDictionary:self.openModel.infoModel.webviewParams];
    mutdict[@"iPadLayoutMode"] = FGRCModel;
    [self.openModel.infoModel setWebviewParams:[mutdict copy]];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.webView.adfg_engine fireEvent:ADFGiPadLayoutSizeWillChange params:@{@"width":@(size.width),@"height":@(size.height)} resultBlock:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *) && self.openModel.darkModeType == ADFGDarkModeTypeSystem) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
                [self fireEvent:ADFGChangeColorScheme params:@{@"scheme" : @"dark"} resultBlock:nil];
            } else {
                [self fireEvent:ADFGChangeColorScheme params:@{@"scheme" : @"light"} resultBlock:nil];
            }
        }
    }
}

#pragma mark - Close
- (void)close
{
    [self willMoveToParentViewController:nil];
    [self removeFromParentViewController];
    [self.view removeFromSuperview];
    if (self.closeBlock) {
        self.closeBlock();
    }
    enableOpen = YES;
}


#pragma mark - webview
- (void)startRequset
{
   [self registerJSBridge];
   [self retryFetch];
}

- (void)retryFetch
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.openModel.infoModel.url];
    request.timeoutInterval = 10.0;
    [self.webView loadRequest:request];
}

- (void)registerJSBridge {
    adfg_weakify(self)
    [self.webView.adfg_engine registerBridge:^(ADFGBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(ADFGGetParams);
        maker.handler(^(NSDictionary * _Nullable params, ADFGBridgeCallback  _Nonnull callback, id<ADFGBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            if (callback) {
                adfg_strongify(self)
                callback(ADFGBridgeMsgSuccess,self.openModel.infoModel.webviewParams,nil);
            }
        });
    }];
    
    [self.webView.adfg_engine registerBridge:^(ADFGBridgeRegisterMaker * _Nonnull maker) {
        maker.bridgeName(ADFGCloseContainer);
        maker.handler(^(NSDictionary * _Nullable params, ADFGBridgeCallback  _Nonnull callback, id<ADFGBridgeEngine>  _Nonnull engine, UIViewController * _Nullable controller) {
            adfg_strongify(self)
            BOOL submitSuccess = [[params objectForKey:@"success"] boolValue];
            if (self.openModel.infoModel.didCloseBlock) {
                self.openModel.infoModel.didCloseBlock(submitSuccess, self.openModel.infoModel);
            }
            [self close];
        });
    }];
}

- (void)configBgColor
{
    if (self.openModel.bgColor) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.backgroundColor = self.openModel.bgColor;
        } completion:nil];
    }
}

- (void)fireEvent:(ADFGBridgeName)eventName params:(nullable NSDictionary *)params resultBlock:(void (^ _Nullable)(NSString * _Nullable))resultBlock {
    [self.webView.adfg_engine fireEvent:eventName params:params resultBlock:resultBlock];
}

#pragma mark - ADFGWKWebViewDelegate
- (void)webViewDidStartLoad:(ADFGWKWebView *)webView
{
    //开始展示loading
    if (self.openModel.needLoading) {
        [self showLoadingStatus];
        [self configBgColor];
    }
}

- (void)webViewDidFinishLoad:(ADFGWKWebView *)webView
{
    if (!self.openModel.infoModel.globalDialog && !self.openModel.parentVC.view.window) {// 非全屏弹框&&页面不可见，判定为打开失败
        if (self.openModel.infoModel.didOpenBlock) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorNotInWindow msg:@"parentVC页面不可见"];
            self.openModel.infoModel.didOpenBlock(NO, self.openModel.infoModel, error);
        }
        [self close];
        return;
    }
    //移除loading状态
    BOOL needShow = YES;
    NSDate* requestFinishAt = [NSDate date];
    // 请求已超时
    if (self.openModel.infoModel.requestTimeoutAt != nil && [requestFinishAt compare:self.openModel.infoModel.requestTimeoutAt] == NSOrderedDescending) {
        needShow = NO;
        if (self.openModel.infoModel.didOpenBlock) {
            NSError *error = [ADFGUtils errorWithCode:ADFGErrorTimeout msg:@"弹框任务已超时"];
            self.openModel.infoModel.didOpenBlock(NO, self.openModel.infoModel, error);
        }
    } else if (self.openModel.infoModel.willOpenBlock) {
        needShow = self.openModel.infoModel.willOpenBlock(self.openModel.infoModel);
        if (!needShow) {
            if (self.openModel.infoModel.didOpenBlock) {
                NSError *error = [ADFGUtils errorWithCode:ADFGErrorBusinessForbidden msg:@"业务禁止弹出"];
                self.openModel.infoModel.didOpenBlock(NO, self.openModel.infoModel, error);
            }
        }
    }
    [self didShowsWebViewWithConfrim:needShow];
}

- (void)didShowsWebViewWithConfrim:(BOOL)show
{
    if (show) {
        if (@available(iOS 13.0, *)) {
            if ((self.openModel.darkModeType == ADFGDarkModeTypeSystem && self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) || self.openModel.darkModeType == ADFGDarkModeTypeDark) {
                [self fireEvent:ADFGChangeColorScheme params:@{@"scheme" : @"dark"} resultBlock:nil];
            }
        }
        self.view.hidden = NO;
        [self stopLoadingStatus];
        [self configBgColor];
        if (self.openModel.infoModel.didOpenBlock) {
            self.openModel.infoModel.didOpenBlock(YES, self.openModel.infoModel, nil);
        }
    } else {
        [self close];
    }
}

- (void)webView:(ADFGWKWebView *)webView didFailLoadWithError:(NSError *)error
{
    if (self.openModel.needLoading) {
        [self showErrorStatus];
    } else {
        // 不展示loading 的case 直接关闭 用户无感知
        [self close];
    }
    if (self.openModel.infoModel.didOpenBlock) {
        self.openModel.infoModel.didOpenBlock(NO, self.openModel.infoModel, error);
    }
}

#pragma mark - statusView action
- (void)showLoadingStatus
{
    [self.view bringSubviewToFront:self.statusView];
    self.statusView.hidden = NO;
    [self.statusView startLoading];
}

- (void)stopLoadingStatus
{
    [_statusView stopLoading];
    _statusView.hidden = YES;
}

- (void)showErrorStatus
{
    [self.view bringSubviewToFront:self.statusView];
    self.statusView.hidden = NO;
    [self.statusView showErrorView];
}

#pragma mark - lazy UI
- (ADFGWKWebView *)webView{
    if (!_webView) {
        _webView = [[ADFGWKWebView alloc] initWithFrame:CGRectZero configuration:[WKWebViewConfiguration new]];
        _webView.opaque = NO;
        _webView.backgroundColor = [UIColor clearColor];
        _webView.scrollView.backgroundColor = [UIColor clearColor];
        _webView.slaveDelates = self;
        ADFGWebViewBridgeEngine *engine = [[ADFGWebViewBridgeEngine alloc] initWithBridgeRegister:ADFGBridgeRegister.new];
        [_webView adfg_installBridgeEngine:engine];
    }
    
    return _webView;
}

- (ADFeedGoodLoadStatusView *)statusView{
    if (!_statusView) {
        _statusView = [[ADFeedGoodLoadStatusView alloc] initWithFrame:self.view.bounds];
        adfg_weakify(self);
        _statusView.retryFetchBlock = ^{
            adfg_strongify(self);
            [self retryFetch];
        };
        _statusView.closeBlock = ^{
            adfg_strongify(self);
            [self close];
        };
        
        [self.view addSubview:_statusView];
    }
    
    return _statusView;
}

@end

@interface ADFeedGoodLoadStatusView()
@property (nonatomic, strong) UIView *loadContentView;
@property (nonatomic, strong) UIImageView *activityImageView;
@property (nonatomic, strong) UIView *errorContentView;
@property (nonatomic, strong) UIView *errorView;
@end

@implementation ADFeedGoodLoadStatusView
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)startLoading{
    [_activityImageView.layer removeAllAnimations];
    self.loadContentView.hidden = NO;
    _errorContentView.hidden = YES;
    CABasicAnimation *ringAnim = [CABasicAnimation animation];
    ringAnim.keyPath = @"transform.rotation.z";
    ringAnim.fromValue = @(0);
    ringAnim.toValue = @(2 * M_PI);
    ringAnim.byValue = @(M_PI);
    ringAnim.duration = 0.5;
    ringAnim.repeatCount = MAXFLOAT;
    
    [self.activityImageView.layer addAnimation:ringAnim forKey:@"ring"];
}

- (void)stopLoading{
    [_activityImageView.layer removeAllAnimations];
    _loadContentView.hidden = YES;
    _errorContentView.hidden = YES;
}

- (void)showErrorView{
    _loadContentView.hidden = YES;
    self.errorView.hidden = NO;
    self.errorContentView.hidden = NO;
}

- (void)retryFecth{
    if (self.retryFetchBlock) {
        self.retryFetchBlock();
    }
}

- (void)close{
    if (self.closeBlock) {
        self.closeBlock();
    }
}

- (UIView *)loadContentView{
    if (!_loadContentView) {
        _loadContentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        _loadContentView.backgroundColor = [UIColor clearColor];
        CGFloat centerX = self.bounds.size.width / 2.0;
        CGFloat centerY = self.bounds.size.height / 2.0;
        _loadContentView.center = CGPointMake(centerX, centerY);
            
        [self addSubview:_loadContentView];
    }
    
    return _loadContentView;
}

- (UIImageView *)activityImageView{
    if (!_activityImageView) {
        _activityImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        UIImage *activityImage = ADFG_compatImageWithName(@"adfg_loading_icon");
        _activityImageView.image = activityImage;
        CGFloat centerX = self.loadContentView.bounds.size.width / 2.0;
        CGFloat centerY = self.loadContentView.bounds.size.height / 2.0;
        _activityImageView.center = CGPointMake(centerX, centerY);
        
        [self.loadContentView addSubview:_activityImageView];
    }
    
    return _activityImageView;
}

- (UIView *)errorContentView{
    if (!_errorContentView) {
        _errorContentView = [[UIView alloc] initWithFrame:self.bounds];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
        [_errorContentView addGestureRecognizer:tap];
        
        [self addSubview:_errorContentView];
    }
    
    return _errorContentView;
}

- (UIView *)errorView{
    if (!_errorView) {
        _errorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 140, 144)];
        _errorView.backgroundColor = [UIColor clearColor];
        CGFloat centerX = self.bounds.size.width / 2.0;
        CGFloat centerY = self.bounds.size.height / 2.0;
        _errorView.center = CGPointMake(centerX, centerY);
        
        UIImageView *errorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(50, 0, 40, 40)];
        UIImage *errorImage = ADFG_compatImageWithName(@"adfg_error_icon");
        errorImageView.image = errorImage;
        [_errorView addSubview:errorImageView];
        
        UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 48, 140, 25)];
        tipLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightMedium];
        tipLabel.textColor = [UIColor whiteColor];
        tipLabel.textAlignment = NSTextAlignmentCenter;
        tipLabel.text = @"加载失败";
        [_errorView addSubview:tipLabel];
        
        UILabel *tipSubLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 79, 140, 17)];
        tipSubLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
        tipSubLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        tipSubLabel.textAlignment = NSTextAlignmentCenter;
        tipSubLabel.text = @"点击页面任意区域关闭";
        [_errorView addSubview:tipSubLabel];
        
        UIButton *retryButton = [UIButton buttonWithType:UIButtonTypeCustom];
        retryButton.frame = CGRectMake(40, 112, 60, 32);
        [retryButton setTitle:@"刷新" forState:UIControlStateNormal];
        retryButton.titleLabel.textColor = [UIColor whiteColor];
        retryButton.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
        retryButton.layer.cornerRadius = 6.0;
        retryButton.layer.borderWidth = 1.0;
        retryButton.layer.borderColor = [UIColor whiteColor].CGColor;
        retryButton.clipsToBounds = YES;
        [retryButton addTarget:self action:@selector(retryFecth) forControlEvents:UIControlEventTouchUpInside];
        [_errorView addSubview:retryButton];
        [self.errorContentView addSubview:_errorView];
    }
    
    return _errorView;
}

@end



