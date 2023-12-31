//
//  CJPayExceptionViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2019/11/10.
//

#import "CJPayExceptionViewController.h"
#import "CJPayCommonExceptionView.h"
#import "CJPayUIMacro.h"
#import "CJPayFullPageBaseViewController+Theme.h"

@interface CJPayExceptionViewController ()

@property (nonatomic, strong) CJPayCommonExceptionView *exceptionView;

@property (nonatomic, copy) NSString *mainTitle;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *buttonTitle;

@property (nonatomic, assign) BOOL isClickActionButton;

@end

@implementation CJPayExceptionViewController

- (instancetype)initWithMainTitle:(nullable NSString *)mainTitle
                     subTitle:(nullable NSString *)subTitle
                  buttonTitle:(nullable NSString *)buttonTitle {
    self = [super init];
    if (self) {
        self.mainTitle = mainTitle;
        self.subTitle = subTitle;
        self.buttonTitle = buttonTitle;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self p_track:@"wallet_pv_limit_page_imp"params:@{}];
}

- (void)setupUI {
    [self.view addSubview:self.exceptionView];
    [self.view bringSubviewToFront:self.navigationBar];
    CJPayMasMaker(self.exceptionView, {
        make.bottom.right.left.equalTo(self.view);
        make.top.equalTo(self.view).offset([self navigationHeight]);
    });
}

- (CJPayCommonExceptionView *)exceptionView {
    if (!_exceptionView) {
        @CJWeakify(self)
        CJPayCommonExceptionView *defaultExceptionView = [[CJPayCommonExceptionView alloc] initWithFrame:CGRectZero mainTitle:self.mainTitle subTitle:self.subTitle buttonTitle:self.buttonTitle];
        defaultExceptionView.actionBlock = ^{
            @CJStrongify(self)
            self.isClickActionButton = YES;
            [self back];
        };
        _exceptionView = defaultExceptionView;
    }
    
    return _exceptionView;
}

- (void)back {
    NSString *buttonName = self.isClickActionButton ? @"我知道了" : @"返回";
    [self p_track:@"wallet_pv_limit_page_click" params:@{@"button_name" : buttonName}];
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:^{
            CJ_CALL_BLOCK(self.closeblock);
        }];
    } else {
        @CJWeakify(self)
        [self.navigationController cj_popViewControllerAnimated:YES completion:^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.closeblock);
        }];
    }
}


+ (void)gotoThrotterPageWithAppId:(NSString *)appId
                      merchantId:(NSString *)merchantId
                           fromVC:(nonnull UIViewController *)referVC
                       closeBlock:(void (^ _Nullable)(void))closeBlock
                           source:(nonnull NSString *)source {
    CJPayExceptionViewController *vc = [[CJPayExceptionViewController alloc] initWithMainTitle:CJPayLocalizedStr(@"系统拥挤") subTitle:CJPayLocalizedStr(@"排队人数太多了，请休息片刻后再试") buttonTitle:CJPayLocalizedStr(@"知道了")];
    vc.appId = appId;
    vc.merchantId = merchantId;
    vc.source = source;
    vc.closeblock = [closeBlock copy];
    
    UINavigationController *navi = [UIViewController cj_foundTopViewControllerFrom:referVC].navigationController;
    if ([navi isKindOfClass:CJPayNavigationController.class]) {
        [navi pushViewController:vc animated:YES];
    } else {
        CJPayNavigationController *navVC = [CJPayNavigationController instanceForRootVC:vc];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIViewController cj_foundTopViewControllerFrom:referVC] presentViewController:navVC animated:YES completion:nil];
        });
    }
}

- (void)p_track:(NSString *)eventName params:(NSDictionary *)params {
    
    NSMutableDictionary *mutableDic = [NSMutableDictionary new];
    [mutableDic addEntriesFromDictionary:@{@"app_id": CJString(self.appId), @"merchant_id": CJString(self.merchantId), @"is_chaselight": @"1", @"type": CJString(self.source)}];
    [mutableDic addEntriesFromDictionary:params];
    [CJTracker event:eventName params: [mutableDic copy]];
}

@end
