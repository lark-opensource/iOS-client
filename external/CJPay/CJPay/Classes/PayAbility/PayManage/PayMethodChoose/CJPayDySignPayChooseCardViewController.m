//
//  CJPayDySignPayChooseCardViewController.m
//  CJPaySandBox
//
//  Created by ByteDance on 2023/6/30.
//

#import "CJPayDySignPayChooseCardViewController.h"
#import "CJPaySignPayChoosePayMethodManager.h"
#import "CJPaySignPayChoosePayMethodView.h"
#import "CJPaySignPayChoosePayMethodGroupModel.h"
#import "CJPaySignPayChoosePayMethodModel.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayOutDisplayInfoModel.h"

#import "CJPayUIMacro.h"

@interface CJPayDySignPayChooseCardViewController ()

@property (nonatomic, weak) CJPaySignPayChoosePayMethodManager *manager;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) UILabel *warningLabel; // 警告
@property (nonatomic, strong) UIView *warningContentView; // 警告区域
@property (nonatomic, copy) NSArray<CJPaySignPayChoosePayMethodView *> *signPayChoosePayMethodViewArray; //分区的View

@property (nonatomic, copy) NSArray<CJPaySignPayChoosePayMethodGroupModel *> *payMethodsGroupModelArray; // 所有支付方式数据

@end

@implementation CJPayDySignPayChooseCardViewController

- (instancetype)initWithManager:(CJPaySignPayChoosePayMethodManager *)manager {
    self = [super init];
    if (self) {
        self.manager = manager;
    }
    return self;
}

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    @CJWeakify(self)
    // 选卡页加载时从manager处获取支付方式数据
    [self.manager getChoosePayMethodList:^(NSArray<CJPaySignPayChoosePayMethodGroupModel *> *payMethodList) {
        @CJStrongify(self)
        if (!Check_ValidArray(payMethodList)) {
            [super back];
            return;
        }
        self.payMethodsGroupModelArray = payMethodList;
        [self p_setupUI];
        [self p_postTrack];
    }];
    self.navigationBar.title = CJPayLocalizedStr(@"选择优先付款方式");
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.manager trackerWithEventName:@"wallet_orderqueue_setup_method_close" params:@{}];
}

#pragma mark - private func

- (void)p_postTrack {
    NSMutableArray *methodList = [NSMutableArray new];
    __block NSString *methodText;
    
    [self.payMethodsGroupModelArray enumerateObjectsUsingBlock:^(CJPaySignPayChoosePayMethodGroupModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.subPayTypeIndexList enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [methodList btd_addObject:[obj toSubPayMethodInfoTrackerDic]];
            if (obj.isSelected) {
                methodText = obj.title;
            }
        }];
    }];
    [self.manager trackerWithEventName:@"wallet_orderqueue_setup_method_show" params:@{
        @"orderqueue_source" : @"wallet_withhold_merchant_project_page",
        @"method" : CJString(methodText),
        @"byte_sub_pay_list" : CJString([methodList btd_jsonStringEncoded]),
    }];
}

- (void)p_setupUI {
    [self.contentView addSubview:self.warningContentView];
    [self.warningContentView addSubview:self.warningLabel];
    
    CJPayMasMaker(self.warningContentView, {
        make.top.left.right.mas_equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.warningLabel, {
        make.left.mas_equalTo(self.warningContentView).mas_offset(16);
        make.right.mas_equalTo(self.warningContentView).mas_offset(-16);
        make.top.mas_equalTo(self.warningContentView).mas_offset(12);
        make.bottom.mas_equalTo(self.warningContentView).mas_offset(-12);
    });
    
    [self p_updateWarningArea:self.warningText];
    
    [self.contentView addSubview:self.scrollView];
    [self.scrollView addSubview:self.scrollContentView];
    
    CJPayMasMaker(self.scrollView, {
        make.top.equalTo(!Check_ValidString(self.warningText) ? self.contentView : self.warningContentView.mas_bottom);
        make.left.right.bottom.mas_equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.view);
    });
    
    self.signPayChoosePayMethodViewArray = [self p_buildSignPayChoosePayMethodModel];
    
    __block UIView *preView = self.scrollContentView;
    [self.signPayChoosePayMethodViewArray enumerateObjectsUsingBlock:^(CJPaySignPayChoosePayMethodView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.scrollContentView addSubview:obj];
        NSInteger choosePayMethodViewArrayCount = self.signPayChoosePayMethodViewArray.count;
        CJPayMasMaker(obj, {
            make.top.mas_equalTo([preView isEqual:self.scrollContentView] ? preView :preView.mas_bottom).mas_offset(8);
            make.left.mas_equalTo(self.scrollContentView).mas_offset(12);
            make.right.mas_equalTo(self.scrollContentView).mas_offset(-12);
            if (idx == choosePayMethodViewArrayCount - 1) {
                make.bottom.mas_equalTo(self.scrollContentView);
            }
        });
        preView = obj;
    }];
}

- (NSArray<CJPaySignPayChoosePayMethodView *> *)p_buildSignPayChoosePayMethodModel {
    NSMutableArray<CJPaySignPayChoosePayMethodView *> *choosePayMethodViewArray = [NSMutableArray new];
    @CJWeakify(self)
    [self.payMethodsGroupModelArray enumerateObjectsUsingBlock:^(CJPaySignPayChoosePayMethodGroupModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        CJPaySignPayChoosePayMethodModel *choosePayMethodModel = [CJPaySignPayChoosePayMethodModel new];
        choosePayMethodModel.groupTitle = obj.groupTitle;
        choosePayMethodModel.displayNewBankCardCount = obj.displayNewBankCardCount;
        choosePayMethodModel.methodList = obj.subPayTypeIndexList;
        CJPaySignPayChoosePayMethodView *choosePayMethodView = [[CJPaySignPayChoosePayMethodView alloc] initWithPayMethodViewModel:choosePayMethodModel];
        choosePayMethodView.layer.cornerRadius = 8;
        choosePayMethodView.layer.masksToBounds = YES;
        @CJWeakify(self)
        choosePayMethodView.didSelectedBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull selectConfig, UIView  * _Nullable loadingView) {
            @CJStrongify(self)
            [self.manager trackerWithEventName:@"wallet_orderqueue_setup_method_click" params:@{
                @"orderqueue_source" : @"wallet_withhold_merchant_project_page",
                @"method" : CJString(selectConfig.title),
            }];
            [self didSelectPayMethod:selectConfig loadingView:loadingView];
        };
        [choosePayMethodViewArray btd_addObject:choosePayMethodView];
    }];
    
    return [choosePayMethodViewArray copy];
}

- (void)p_updateWarningArea:(NSString *)warningText {
    self.warningContentView.hidden = !Check_ValidString(warningText);
    self.warningLabel.text = CJString(warningText);
}

- (void)didSelectPayMethod:(CJPayDefaultChannelShowConfig *)showConfig loadingView:loadingView {
    if (showConfig.canUse && showConfig.type != BDPayChannelTypeAddBankCard) {
        for (NSInteger index = 0; index < self.payMethodsGroupModelArray.count; index++) {
            CJPaySignPayChoosePayMethodView *choosePayMethodView = [self.signPayChoosePayMethodViewArray cj_objectAtIndex:index];
            [choosePayMethodView updatePayMethodViewBySelectConfig:showConfig];
        }
    }
    CJ_CALL_BLOCK(self.didSelectedBlock, showConfig, loadingView);
}

// 选卡页高度支持外部定制
- (CGFloat)containerHeight {
    if (self.height <= CGFLOAT_MIN) {
        return CJ_HALF_SCREEN_HEIGHT_LOW;
    } else {
        return self.height;
    }
}

#pragma mark - lazy load

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.backgroundColor  = [UIColor cj_f8f8f8ff];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.clipsToBounds = YES;
        _scrollView.bounces = YES;
        if (@available(iOS 11.0, *)) {
            [_scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        }
    }
    return _scrollView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
        _scrollContentView.backgroundColor  = [UIColor cj_f8f8f8ff];
        _scrollContentView.clipsToBounds = NO;
    }
    return _scrollContentView;
}

- (UILabel *)warningLabel {
    if (!_warningLabel) {
        _warningLabel = [UILabel new];
        _warningLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _warningLabel.font = [UIFont cj_fontOfSize:13];
        _warningLabel.textAlignment = NSTextAlignmentNatural;
        _warningLabel.numberOfLines = 0;
    }
    return _warningLabel;
}

- (UIView *)warningContentView {
    if (!_warningContentView) {
        _warningContentView = [UIView new];
        _warningContentView.backgroundColor = [UIColor cj_161823WithAlpha:0.05];
    }
    return _warningContentView;
}

@end
