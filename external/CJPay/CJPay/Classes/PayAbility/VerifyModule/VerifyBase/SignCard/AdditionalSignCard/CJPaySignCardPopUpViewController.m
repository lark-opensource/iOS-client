//
//  CJPaySignCardPopUpViewController.m
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/7/26.
//

#import "CJPaySignCardPopUpViewController.h"

#import "CJPayStyleButton.h"

@interface CJPaySignCardPopUpViewController()

@property (nonatomic, strong, readwrite) CJPaySignCardView *tipsView;
@property (nonatomic, strong) CJPaySignCardInfo *signCardInfoModel;

@end

@implementation CJPaySignCardPopUpViewController

- (instancetype)initWithSignCardInfoModel:(CJPaySignCardInfo *)signCardInfoModel {
    self = [super init];
    if (self) {
        _signCardInfoModel = signCardInfoModel;
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    
    self.containerView.layer.cornerRadius = 12;
    [self.containerView addSubview:self.tipsView];
    CJPayMasMaker(self.tipsView, {
        make.edges.equalTo(self.containerView);
    })
    
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
    });
    
    [self.tipsView updateWithSignCardInfo:self.signCardInfoModel];
    [self p_trackWithEvent:@"wallet_cashier_update_bank_pop_imp" params:@{
        @"bank_name" : CJString(self.bankNameTitle)
    }];
}

- (void)p_trackWithEvent:(NSString *)eventName params:(NSDictionary *)params {
    if (self.trackDelegate && [self.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackDelegate event:eventName params:params];
    }
}

- (void)p_confirmButtonClick {
    [self p_trackWithEvent:@"wallet_cashier_update_bank_pop_click" params:@{
        @"bank_name" : CJString(self.bankNameTitle),
        @"button_name" : CJString(self.tipsView.confirmButton.titleLabel.text)
    }];
    CJ_CALL_BLOCK(self.confirmButtonClickBlock, self.tipsView.confirmButton);
}

- (void)p_closeButtonClick {
    [self p_trackWithEvent:@"wallet_cashier_update_bank_pop_click" params:@{
        @"bank_name" : CJString(self.bankNameTitle),
        @"button_name" : @"退出"
    }];
    CJ_CALL_BLOCK(self.closeButtonClickBlock);
}

- (CJPaySignCardView *)tipsView {
    if (!_tipsView) {
        _tipsView = [CJPaySignCardView new];
        [_tipsView.confirmButton addTarget:self action:@selector(p_confirmButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_tipsView.closeButton addTarget:self action:@selector(p_closeButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _tipsView;
}

@end
