//
//  CJPayBizResultPageViewController.m
//  CJPaySandBox
//
//  Created by 高航 on 2022/11/29.
//

#import "CJPayFullResultPageViewController.h"
#import "CJPayFullResultPageView.h"
#import "CJPayResultPageModel.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayHalfPageBaseViewController.h"

@interface CJPayFullResultPageViewController ()

@property (nonatomic, strong) CJPayFullResultPageView *resultPageView;
@property (nonatomic, strong) CJPayResultPageModel *model;
@property (nonatomic, copy) NSDictionary *trackerParams;
@property (nonatomic, assign) BOOL isFirstDidAppear;

@end

@implementation CJPayFullResultPageViewController

- (instancetype)initWithCJResultModel:(CJPayResultPageModel *)model  trackerParams:(NSDictionary *)params{
    self = [super init];
    if (self) {
        _model = model;
        _trackerParams = params;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_updateTrackerParams];
    [self p_setupUI];
    [self.resultPageView loadLynxCard];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self p_pageShowEvent];
    
}

#pragma mark private method

- (void)p_updateTrackerParams {
    NSMutableDictionary *finalTrackerParams = [NSMutableDictionary dictionaryWithDictionary:self.trackerParams];
    NSMutableDictionary *resultInfo = [[NSMutableDictionary alloc] init];
    [self.model.resultPageInfo.showInfos enumerateObjectsUsingBlock:^(CJPayPayInfoDesc *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [resultInfo cj_setObject:CJString(obj.desc) forKey:CJString(obj.name)];
    }];
    [finalTrackerParams cj_setObject:CJString([[resultInfo copy] btd_jsonStringEncoded]) forKey:@"cjpay_result_info"];
    self.trackerParams = finalTrackerParams;
}

- (void)p_pageShowEvent {
    CJPayResultPageInfoModel *pageInfoModel = self.model.resultPageInfo;
    NSMutableDictionary *params = [NSMutableDictionary new];
    __block NSString *dynamicComponents = @"";
    [pageInfoModel.dynamicComponents enumerateObjectsUsingBlock:^(CJPayDynamicComponents * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dynamicComponents = dynamicComponents.length > 0 ? [dynamicComponents stringByAppendingFormat:@",%@" , CJString(obj.name)] : [dynamicComponents stringByAppendingString:CJString(obj.name)];;
    }];
    [params cj_setObject:CJString(pageInfoModel.voucherOptions.desc) forKey:@"voucher_options"];
    [params cj_setObject:CJString(pageInfoModel.dynamicData) forKey:@"dynamic_data"];
    [params cj_setObject:CJString(dynamicComponents) forKey:@"dynamic_components"];
    [params cj_setObject:@"native支付结果页" forKey:@"project"];
    [params addEntriesFromDictionary:self.trackerParams];
    [CJTracker event:@"wallet_cashier_result_page_imp" params:params];
}

- (void)p_setupUI {
    [self.view addSubview:self.resultPageView];
    self.navigationBar.hidden = YES;
    CJPayMasMaker(self.resultPageView, {
        make.edges.equalTo(self.view);
    });
    
}

- (void)p_close {
    CJ_CALL_BLOCK(self.closeCompletion);
    [super back];
}

- (void)p_closeActionAfterTime:(int)time {
    if (time < 0) { // 小于0的话，不关闭结果页，让用户手动关闭
        return;
    }
    @CJWeakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self);
        [self p_close];
    });
}

#pragma mark lazy init
- (CJPayFullResultPageView *)resultPageView {
    if (!_resultPageView) {
        _resultPageView = [[CJPayFullResultPageView alloc] initWithCJOrderModel:self.model];
        @CJWeakify(self)
        _resultPageView.completion = ^{
            @CJStrongify(self)
            [self p_close];
        };
        _resultPageView.trackerParams = self.trackerParams;
    }
    return _resultPageView;
}

@end
