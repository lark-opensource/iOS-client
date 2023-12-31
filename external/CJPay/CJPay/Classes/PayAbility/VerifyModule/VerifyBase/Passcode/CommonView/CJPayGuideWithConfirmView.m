//
//  CJPayGuideWithConfirmView.m
//  Pods
//
//  Created by chenbocheng on 2022/3/31.
//

#import "CJPayGuideWithConfirmView.h"

#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "CJPaySwitch.h"

@interface CJPayGuideWithConfirmView ()

@property (nonatomic, assign) BOOL isShowButton;
@property (nonatomic, strong) CJPayCommonProtocolModel *protocolModel;
@property (nonatomic, strong) UIView *clickView;

@end

@implementation CJPayGuideWithConfirmView

- (instancetype)initWithCommonProtocolModel:(CJPayCommonProtocolModel *)protocolModel isShowButton:(BOOL)isShowButton {
    self = [super init];
    if (self) {
        self.protocolModel = protocolModel;
        self.isShowButton = isShowButton;
        [self p_setupUI];
    }
    return self;
}

- (void)updateProtocolModel:(CJPayCommonProtocolModel *)protocolModel isShowButton:(BOOL)isShowButton {
    self.protocolModel = protocolModel;
    self.isShowButton = isShowButton;
    [self.protocolView updateWithCommonModel:protocolModel];
    [self p_updateViewsConstraint];
}

#pragma mark - private method
- (void)p_setupUI {
    [self addSubview:self.protocolView];
    [self addSubview:self.confirmButton];
    
    [self p_updateViewsConstraint];
}

- (void)p_updateViewsConstraint {
    if (self.isShowButton) {
        self.confirmButton.hidden = NO;
        CJPayMasReMaker(self.protocolView, {
            if (self.protocolModel.isHorizontalCenterLayout) { //引导文案居中布局
                make.centerX.equalTo(self);
                make.top.equalTo(self);
                make.left.greaterThanOrEqualTo(self);
                make.right.lessThanOrEqualTo(self);
            } else {
                make.top.left.right.equalTo(self);
            }
        });
        
        CJPayMasReMaker(self.confirmButton, {
            make.top.equalTo(self.protocolView.mas_bottom).offset(12);
            make.left.right.bottom.equalTo(self);
            make.height.mas_equalTo(44);
            make.bottom.equalTo(self);
        });
    } else {
        self.confirmButton.hidden = YES;
        CJPayMasReMaker(self.protocolView, {
            if (self.protocolModel.isHorizontalCenterLayout) { //引导文案居中布局
                make.centerX.equalTo(self);
                make.top.bottom.equalTo(self);
                make.left.greaterThanOrEqualTo(self);
                make.right.lessThanOrEqualTo(self);
            } else {
                make.top.left.right.bottom.equalTo(self);
            }
        });
    }
    // 动态化布局时，通过clickview增大switch/checkbox点击热区
    UIView *clickBtn = [self.protocolView getClickBtnView];
    if (self.protocolModel.isHorizontalCenterLayout && clickBtn) {
        [self addSubview:self.clickView];
        CJPayMasReMaker(self.clickView, {
            make.width.height.mas_equalTo(36);
            make.center.equalTo(clickBtn);
        });
    }
}

- (void)p_switch {
    [self.protocolView agreeCheckBoxTapped];
}

#pragma mark - Override
// 增大点击热区
//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
//    UIView *view = [super hitTest:point withEvent:event];
//    if (view == nil) {
//        // 使clickView超出父视图部分仍可响应点击事件
//        UIView *respondView = self.clickView;
//        CGPoint temPoint = [respondView convertPoint:point fromView:self];
//        BOOL canRespondHit = !respondView.isHidden && respondView.isUserInteractionEnabled && respondView.alpha >= 0.1;
//        if (canRespondHit && CGRectContainsPoint(self.clickView.bounds, temPoint)) {
//            view = respondView;
//        }
//    }
//    return view;
//}

#pragma mark - lazy views

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:self.protocolModel];
    }
    return _protocolView;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmButton.hidden = YES;
    }
    return _confirmButton;
}

- (UIView *)clickView {
    if (!_clickView) {
        _clickView = [UIView new];
        _clickView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_switch)];
        [_clickView addGestureRecognizer:tapGesture];
    }
    return _clickView;
}

@end
