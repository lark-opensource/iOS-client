//
//  CJPayDyTextPopUpViewController.m
//  Pods
//
//  Created by 孟源 on 2021/11/1.
//

#import "CJPayDyTextPopUpViewController.h"
#import "CJPayLineUtil.h"
#import "CJPayButton.h"
#import "CJPayNavigationController.h"

@interface CJPayDyTextPopUpViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) CJPayButton *mainOperation;
@property (nonatomic, strong) CJPayButton *secondOperation;
@property (nonatomic, strong) CJPayButton *thirdOperation;
@property (nonatomic, strong) CJPayDyTextPopUpModel *model;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, assign) BOOL isOuterContentView;
@end

@implementation CJPayDyTextPopUpViewController

- (instancetype)initWithPopUpModel:(CJPayDyTextPopUpModel *)model {
    if (self = [super init]) {
        _model = model;
    }
    return self;
}

- (instancetype)initWithPopUpModel:(CJPayDyTextPopUpModel *)model contentView:(UIView *)contentView {
    self = [super init];
    if (self) {
        _model = model;
        if (_model.type == CJPayTextPopUpTypeDefault) {
            if (!Check_ValidString(_model.mainOperation)) {
                _model.mainOperation = CJPayLocalizedStr(@"知道了");
            }
        } else if (_model.type == CJPayTextPopUpTypeHorizontal) {
            if (!Check_ValidString(_model.mainOperation)) {
                _model.mainOperation = CJPayLocalizedStr(@"确定");
            }
            if (!Check_ValidString(_model.secondOperation)) {
                _model.secondOperation = CJPayLocalizedStr(@"取消");
            }
        }
        _contentView = contentView;
        _isOuterContentView = YES;
    }
    return self;
}

- (void)setupUI {
    [super setupUI];
    self.containerView.layer.cornerRadius = 12;
    [self.containerView.layer setMasksToBounds:YES];
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
    });
    
    if (CJ_Pad) {
        CJPayMasReMaker(self.containerView, {
            make.center.equalTo(self.view);
            make.width.mas_lessThanOrEqualTo(272);
        });
    }
    [self.containerView addSubview:self.mainOperation];

    if (self.isOuterContentView) {
        [self.containerView addSubview:self.contentView];
       
        CJPayMasMaker(self.contentView, {
            make.top.left.right.equalTo(self.containerView);
            make.bottom.equalTo(self.mainOperation.mas_top);
        });
        
        CJPayMasMaker(self.mainOperation, {
            make.right.equalTo(self.containerView);
            make.bottom.equalTo(self.containerView);
            make.height.mas_equalTo(48);
            if (self.model.type == CJPayTextPopUpTypeHorizontal) {
                make.width.equalTo(self.containerView).dividedBy(2);
            } else {
                make.width.equalTo(self.containerView);
            }
        });
        
    } else {
        self.contentView = [UIView new];
        [self.containerView addSubview:self.contentView];
        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.contentLabel];
       
        CJPayMasMaker(self.contentView, {
            make.top.left.right.equalTo(self.containerView);
        });
        
        CJPayMasMaker(self.titleLabel, {
            make.left.equalTo(self.contentView).offset(20);
            make.right.equalTo(self.contentView).offset(-20);
            make.top.equalTo(self.contentView).offset(24);
        });
        
        CJPayMasMaker(self.contentLabel, {
            make.left.right.equalTo(self.titleLabel);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(Check_ValidString(self.model.title) ? 8 : 0);
        });
        
        CJPayMasMaker(self.contentView, {
            make.bottom.equalTo(Check_ValidString(self.model.content) ? self.contentLabel : self.titleLabel).offset(24);
        });
        
        CJPayMasMaker(self.mainOperation, {
            make.right.equalTo(self.contentView);
            make.top.equalTo(self.contentView.mas_bottom);
            make.height.mas_equalTo(48);
            if (self.model.type == CJPayTextPopUpTypeHorizontal) {
                make.width.equalTo(self.containerView).dividedBy(2);
            } else {
                make.width.equalTo(self.containerView);
            }
        });
    }
    
    [CJPayLineUtil addBottomLineToView:self.contentView marginLeft:0 marginRight:0 marginBottom:0];
    UIView *bottomView = self.mainOperation;
    switch (self.model.type) {
        case CJPayTextPopUpTypeHorizontal:
            [self.containerView addSubview:self.secondOperation];
            CJPayMasMaker(self.secondOperation, {
                make.left.equalTo(self.containerView);
                make.right.equalTo(self.mainOperation.mas_left);
                make.top.bottom.equalTo(self.mainOperation);
            });
            [CJPayLineUtil addRightLineToView:self.secondOperation marginTop:0 marginBottom:0 marginRight:0];
            break;
        case CJPayTextPopUpTypeVertical:
            [CJPayLineUtil addBottomLineToView:self.mainOperation marginLeft:0 marginRight:0 marginBottom:0];
            [self.containerView addSubview:self.secondOperation];
            CJPayMasMaker(self.secondOperation, {
                make.top.equalTo(self.mainOperation.mas_bottom);
                make.left.right.equalTo(self.mainOperation);
                make.height.mas_equalTo(48);
            });
            bottomView = self.secondOperation;
            break;
        case CJPayTextPopUpTypeLongVertical:
            [CJPayLineUtil addBottomLineToView:self.mainOperation marginLeft:0 marginRight:0 marginBottom:0];
            [self.containerView addSubview:self.secondOperation];
            CJPayMasMaker(self.secondOperation, {
                make.top.equalTo(self.mainOperation.mas_bottom);
                make.left.right.equalTo(self.mainOperation);
                make.height.mas_equalTo(48);
            });
            
            [CJPayLineUtil addBottomLineToView:self.secondOperation marginLeft:0 marginRight:0 marginBottom:0];
            [self.containerView addSubview:self.thirdOperation];
            CJPayMasMaker(self.thirdOperation, {
                make.top.equalTo(self.secondOperation.mas_bottom);
                make.left.right.equalTo(self.secondOperation);
                make.height.mas_equalTo(48);
            });
            bottomView = self.thirdOperation;
            break;
        default:
            break;
    }
    if (!self.isOuterContentView) {
        CJPayMasMaker(self.containerView, {
            make.bottom.equalTo(bottomView);
        });
    }
}

- (void)p_clickMainOperation {
    if (self.isOuterContentView) {
        @CJWeakify(self);
        [self dismissSelfWithCompletionBlock:^{
            @CJStrongify(self);
            CJ_CALL_BLOCK(self.model.didClickMainOperationBlock);
        }];
    } else {
        CJ_CALL_BLOCK(self.model.didClickMainOperationBlock);
    }
}

- (void)p_clickSecondOperation {
    if (self.isOuterContentView) {
        @CJWeakify(self);
        [self dismissSelfWithCompletionBlock:^{
            @CJStrongify(self);
            CJ_CALL_BLOCK(self.model.didClickSecondOperationBlock);
        }];
    } else {
        CJ_CALL_BLOCK(self.model.didClickSecondOperationBlock);
    }
}

- (void)p_clickThirdOperation {
    if (self.isOuterContentView) {
        @CJWeakify(self);
        [self dismissSelfWithCompletionBlock:^{
            @CJStrongify(self);
            CJ_CALL_BLOCK(self.model.didClickThirdOperationBlock);
        }];
    } else {
        CJ_CALL_BLOCK(self.model.didClickThirdOperationBlock);
    }
}

- (NSTextAlignment)p_mapAlignment:(CJPayTextPopUpContentAlignmentType)type {
    if (type == CJPayTextPopUpContentAlignmentTypeDefault) {
        return NSTextAlignmentCenter;
    } else if (type == CJPayTextPopUpContentAlignmentTypeLeft) {
        return NSTextAlignmentLeft;
    } else if (type == CJPayTextPopUpContentAlignmentTypeCenter) {
        return NSTextAlignmentCenter;
    } else if (type == CJPayTextPopUpContentAlignmentTypeRight) {
        return NSTextAlignmentRight;
    }
    return NSTextAlignmentCenter;
}

- (void)showOnTopVC:(UIViewController *)vc {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:vc];
    if (!CJ_Pad && topVC.navigationController && [topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        [topVC.navigationController pushViewController:self animated:YES];
    } else {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [self presentWithNavigationControllerFrom:topVC useMask:YES completion:nil];
    }
}

#pragma mark - lazy load
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = CJString(self.model.title);
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [UILabel new];
        _contentLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _contentLabel.font = [UIFont cj_fontOfSize:14];
        _contentLabel.textAlignment = [self p_mapAlignment:self.model.contentAlignment];
        _contentLabel.text = CJString(self.model.content);
        _contentLabel.numberOfLines = 0;
    }
    return _contentLabel;
}

- (CJPayButton *)mainOperation {
    if (!_mainOperation) {
        _mainOperation = [CJPayButton new];
        [_mainOperation setTitleColor:self.model.mainOperationColor ?: [UIColor cj_161823ff] forState:UIControlStateNormal];
        _mainOperation.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_mainOperation setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_f8f8f8ff]] forState:UIControlStateSelected];
        [_mainOperation setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_f8f8f8ff]] forState:UIControlStateHighlighted];
        [_mainOperation cj_setBtnTitle:CJString(self.model.mainOperation)];
        [_mainOperation addTarget:self action:@selector(p_clickMainOperation) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mainOperation;
}

- (CJPayButton *)secondOperation {
    if (!_secondOperation) {
        _secondOperation = [CJPayButton new];
        [_secondOperation setTitleColor:self.model.secondOperationColor ?: [UIColor cj_161823ff] forState:UIControlStateNormal];
        [_secondOperation setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_f8f8f8ff]] forState:UIControlStateSelected];
        [_secondOperation setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_f8f8f8ff]] forState:UIControlStateHighlighted];
        _secondOperation.titleLabel.font = [UIFont cj_fontOfSize:15];
        [_secondOperation cj_setBtnTitle:CJString(self.model.secondOperation)];
        [_secondOperation addTarget:self action:@selector(p_clickSecondOperation) forControlEvents:UIControlEventTouchUpInside];
    }
    return _secondOperation;
}

- (CJPayButton *)thirdOperation {
    if (!_thirdOperation) {
        _thirdOperation = [CJPayButton new];
        [_thirdOperation setTitleColor:[UIColor cj_161823ff] forState:UIControlStateNormal];
        [_thirdOperation setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_f8f8f8ff]] forState:UIControlStateSelected];
        [_thirdOperation setBackgroundImage:[UIImage cj_imageWithColor:[UIColor cj_f8f8f8ff]] forState:UIControlStateHighlighted];
        _thirdOperation.titleLabel.font = [UIFont cj_fontOfSize:15];
        [_thirdOperation cj_setBtnTitle:CJString(self.model.thirdOperation)];
        [_thirdOperation addTarget:self action:@selector(p_clickThirdOperation) forControlEvents:UIControlEventTouchUpInside];
    }
    return _thirdOperation;
}

@end
