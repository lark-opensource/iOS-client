//
//  CJPaySignPayDeductDetailView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/29.
//

#import "CJPaySignPayDeductDetailView.h"
#import "CJPaySignPayDescView.h"
#import "CJPaySignPayDeductMethodView.h"
#import "CJPaySignPayModel.h"
#import "CJPayDefaultChannelShowConfig.h"

#import "CJPayUIMacro.h"

@interface CJPaySignPayDeductDetailView ()

@property (nonatomic, strong) CJPaySignPayDescView *serverDetailView;
@property (nonatomic, strong) CJPaySignPayDescView *deductTimeView;
@property (nonatomic, strong) UIView *bottomDivideLine;
@property (nonatomic, strong) CJPaySignPayDeductMethodView *deductMethodView;

@property (nonatomic, strong) MASConstraint *deductTimeViewBottomToSelfConstraint;
@property (nonatomic, strong) MASConstraint *serverDetailViewBottomToSelfConstraint;

@end

@implementation CJPaySignPayDeductDetailView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.serverDetailView];
    [self addSubview:self.deductTimeView];
    [self addSubview:self.bottomDivideLine];
    [self addSubview:self.deductMethodView];
}

- (void)setupConstraints {
    CJPayMasMaker(self.serverDetailView, {
        make.left.mas_equalTo(self).mas_offset(16);
        make.right.mas_equalTo(self).mas_offset(-16);
        make.top.mas_equalTo(self);
        self.serverDetailViewBottomToSelfConstraint = make.bottom.mas_equalTo(self);
    });
    
    CJPayMasMaker(self.deductTimeView, {
        make.left.mas_equalTo(self).mas_offset(16);
        make.right.mas_equalTo(self).mas_offset(-16);
        make.top.mas_equalTo(self.serverDetailView.mas_bottom).mas_offset(14);
        self.deductTimeViewBottomToSelfConstraint = make.bottom.mas_equalTo(self);
    });
    
    CJPayMasMaker(self.bottomDivideLine, {
        make.left.right.mas_equalTo(self.deductTimeView);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
        make.top.mas_equalTo(self.deductTimeView.mas_bottom).mas_offset(24);
    });
    
    CJPayMasMaker(self.deductMethodView, {
        make.top.mas_equalTo(self.bottomDivideLine.mas_bottom).mas_offset(17);
        make.left.right.mas_equalTo(self);
        make.bottom.mas_equalTo(self);
    });
}

- (void)updateDeductDetailViewWithModel:(CJPaySignPayModel *)model payMethodClick:(nonnull void (^)(void))payMethodClick {
    [self.serverDetailView updateTitle:CJPayLocalizedStr(@"服务详情") subDesc:model.serviceDesc];
    [self.deductTimeView updateTitle:CJPayLocalizedStr(@"扣款周期") subDesc:model.nextDeductDate];
    if ([self.deductTimeView isHidden]) {
        CJPayMasReMaker(self.bottomDivideLine, {
            make.top.mas_equalTo([self.serverDetailView isHidden] ? self : self.serverDetailView.mas_bottom).mas_offset(24);
            make.left.right.mas_equalTo(self.deductTimeView);
            make.height.mas_equalTo(CJ_PIXEL_WIDTH);
        });
    }
    if (self.isNewUser) {
        self.bottomDivideLine.hidden = YES;
        self.deductMethodView.hidden = YES;
        if ([self.deductTimeView isHidden]) {
            [self.serverDetailViewBottomToSelfConstraint activate];
            [self.deductTimeViewBottomToSelfConstraint deactivate];
        } else {
            [self.deductTimeViewBottomToSelfConstraint activate];
            [self.serverDetailViewBottomToSelfConstraint deactivate];
        }
    } else {
        self.bottomDivideLine.hidden = NO;
        self.deductMethodView.hidden = NO;
        [self.deductMethodView updateDeductMethodViewWithModel:model];
        [self.serverDetailViewBottomToSelfConstraint deactivate];
        [self.deductTimeViewBottomToSelfConstraint deactivate];
        @CJWeakify(self)
        self.deductMethodView.payMethodClick = ^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(payMethodClick);
        };
    }
}

- (void)updateDeductMethodView:(CJPayDefaultChannelShowConfig *)defaultConfig {
    if (!self.isNewUser) {
        self.bottomDivideLine.hidden = NO;
        self.deductMethodView.hidden = NO;
        [self.deductTimeViewBottomToSelfConstraint deactivate];
        [self.serverDetailViewBottomToSelfConstraint deactivate];
    }
    [self.deductMethodView updateDeductMethodViewWithConfig:defaultConfig];
}

#pragma mark - lazy load
- (CJPaySignPayDescView *)serverDetailView {
    if (!_serverDetailView) {
        _serverDetailView = [CJPaySignPayDescView new];
    }
    return _serverDetailView;
}

- (CJPaySignPayDescView *)deductTimeView {
    if (!_deductTimeView) {
        _deductTimeView = [CJPaySignPayDescView new];
    }
    return _deductTimeView;
}

- (UIView *)bottomDivideLine {
    if (!_bottomDivideLine) {
        _bottomDivideLine = [UIView new];
        _bottomDivideLine.backgroundColor = [UIColor cj_divideLineColor];
    }
    return _bottomDivideLine;
}

- (CJPaySignPayDeductMethodView *)deductMethodView {
    if (!_deductMethodView) {
        _deductMethodView = [CJPaySignPayDeductMethodView new];
    }
    return _deductMethodView;
}

@end
