//
//  CJPayAllBankCardListViewController.m
//  Pods
//
//  Created by wangxiaohong on 2020/12/30.
//

#import "CJPayAllBankCardListViewController.h"
#import "CJPayBankCardFooterViewModel.h"
#import "CJPayBankCardAddViewModel.h"
#import "CJPayAccountInsuranceTipView.h"
#import "UIViewController+CJTransition.h"
#import "CJPayBankCardHeaderSafeBannerCellView.h"
#import "CJPayBankCardHeaderSafeBannerViewModel.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "CJPayBankCardItemViewModel.h"
#import "CJPaySDKDefine.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayNavigationBarView.h"
#import "CJPayNavigationController.h"

@interface CJPayAllBankCardListViewController ()

@property (nonatomic, strong) CJPayBankCardHeaderSafeBannerCellView *safeBannerView;

@end

@implementation CJPayAllBankCardListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.showsVerticalScrollIndicator = NO;
    
    [self.navigationBar setTitle:CJPayLocalizedStr(@"全部银行卡")];
    
    [self p_refresh];
    BOOL showInsuranceEntrance = [CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance;
    self.tableView.contentInset = UIEdgeInsetsMake((showInsuranceEntrance ? 12 : 0), 0, CJ_TabBarSafeBottomMargin, 0);
    self.tableView.contentOffset = CGPointMake(0, (showInsuranceEntrance ? -12 : 0));
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(p_SMSSignSuccess:) name:CJPayCardsManageSMSSignSuccessNotification object:nil];
}

- (void)setViewModels:(NSArray<CJPayBaseListViewModel *> *)viewModels {
    _viewModels = [self p_AddSafeGuardViewModel:viewModels];
    [self p_refresh];
}

- (NSArray<CJPayBaseListViewModel *> *)p_AddSafeGuardViewModel:(NSArray<CJPayBaseListViewModel *> *)viewModels {
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        NSMutableArray *mutableArray = [viewModels mutableCopy];
        CJPayBankCardFooterViewModel *qaViewModel = [CJPayBankCardFooterViewModel new];
        qaViewModel.showQAView = NO;
        qaViewModel.showGurdTipView = YES;
        
        __block CGFloat listContentHeight = 0;
        [viewModels enumerateObjectsUsingBlock:^(CJPayBaseListViewModel *  _Nonnull model, NSUInteger idx, BOOL * _Nonnull stop) {
            listContentHeight += [model getViewHeight];
        }];
        
        CGFloat maxListContentHeight = CJ_SCREEN_HEIGHT - CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT - CJ_TabBarSafeBottomMargin;
        if ([CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance) {
            maxListContentHeight -= [self.safeBannerView.viewModel getViewHeight];
        }
        CGFloat tipMinHeight = 32;
        if (maxListContentHeight - listContentHeight > tipMinHeight) {
            self.tableView.bounces = NO;
            tipMinHeight = maxListContentHeight - listContentHeight;
        } else {
            self.tableView.bounces = YES;
        }
        qaViewModel.cellHeight = tipMinHeight;
        [mutableArray addObject:qaViewModel];
        return [mutableArray copy];
    }
    return viewModels;
}

- (BOOL)cjAllowTransition {
    return YES;
}

- (void)p_refresh {
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self.viewModels];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    dic[@(0)] = mutableArray;
    
    [self.dataSource.sectionsDataDic removeAllObjects];
    [self.dataSource.sectionsDataDic addEntriesFromDictionary:dic];
    [self.tableView reloadData];
}

- (void)p_setupUI{
    BOOL showInsuranceEntrance = [CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance;
    if(showInsuranceEntrance){
        [self.view addSubview:self.safeBannerView];
        CJPayMasMaker(self.safeBannerView, {
            make.width.equalTo(self.view);
            make.top.equalTo(self.view).offset([self navigationHeight]);
        });
        CJPayMasReMaker(self.tableView, {
            make.centerX.width.bottom.equalTo(self.view);
            make.top.equalTo(self.view).offset([self navigationHeight]+[self.safeBannerView.viewModel getViewHeight]);
        });
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)p_SMSSignSuccess:(NSNotification*)notification {
    NSString *bankCardId = [notification object];
    __block NSUInteger index = 0;
    __block BOOL searchFlag = NO;
    [self.viewModels enumerateObjectsUsingBlock:^(CJPayBaseListViewModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayBankCardItemViewModel.class]) {
            CJPayBankCardItemViewModel *cardItemViewModel = (CJPayBankCardItemViewModel *)obj;
            if ([cardItemViewModel.cardModel.bankCardId isEqualToString:bankCardId]) {
                index = idx;
                searchFlag = YES;
                *stop = YES;
            }
        }
    }];
    
    if (searchFlag) {
        ((CJPayBankCardItemViewModel *)[self.viewModels cj_objectAtIndex:index]).cardModel.needResign = NO;
        [self p_refresh];
    }
}

#pragma mark Getter
- (CJPayBankCardHeaderSafeBannerCellView *)safeBannerView {
    if(!_safeBannerView) {
        _safeBannerView = [CJPayBankCardHeaderSafeBannerCellView new];
        _safeBannerView.viewModel.viewHeight = 32;
        [_safeBannerView updateSafeString:CJPayLocalizedStr(@"抖音支付全程保障资金与信息安全")];
        _safeBannerView.safeBannerViewModel.passParams = self.passParams;
        _safeBannerView.backgroundColor = self.cjLocalTheme.safeBannerBGColor;
    }
    return _safeBannerView;
}

@end
