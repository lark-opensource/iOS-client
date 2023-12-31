//
//  CJPayPayCancelRetainViewController.m
//  Pods
//
//  Created by chenbocheng on 2021/8/9.
//

#import "CJPayPayCancelRetainViewController.h"
#import "CJPayStyleButton.h"
#import "CJPayRetainVoucherListView.h"

@interface CJPayPayCancelRetainViewController ()

@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel; // 1.0 样式
@property (nonatomic, strong) CJPayStyleButton *topButton;
@property (nonatomic, strong) CJPayButton *closeButton;
@property (nonatomic, strong) CJPayButton *bottomButton;
@property (nonatomic, strong) CJPayRetainVoucherListView *retainVoucherView; // 2.0 样式
@property (nonatomic, strong) CJPayRetainInfoModel *retainInfoModel;

@end

@implementation CJPayPayCancelRetainViewController

- (instancetype)initWithRetainInfoModel:(CJPayRetainInfoModel *)model {
    self = [super init];
    if (self) {
        _retainInfoModel = model;
        _isDescTextAlignmentLeft = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
}

- (void)p_setupUI{
    [super setupUI];
    
    self.containerView.layer.cornerRadius = 12;
    self.topButton.cornerRadius = 4;
    
    [self.containerView addSubview:self.closeButton];
    [self.containerView addSubview:self.mainTitleLabel];
    [self.containerView addSubview:self.subTitleLabel];
    [self.containerView addSubview:self.topButton];
    [self.containerView addSubview:self.bottomButton];
    
    CJPayMasReMaker(self.closeButton, {
        make.top.equalTo(self).offset(12);
        make.left.equalTo(self).offset(12);
        make.width.height.mas_equalTo(20);
    });

    CJPayMasMaker(self.mainTitleLabel, {
        make.top.equalTo(self.containerView).offset(40);
        make.left.equalTo(self.containerView).offset(28);
        make.right.equalTo(self.containerView).offset(-28);
    });
    
    CJPayMasReMaker(self.containerView, {
        make.bottom.equalTo(self.topButton).offset(20);
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
    });
    
    CJPayMasMaker(self.topButton, {
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(44);
    });

    CJPayVoucherType vourcherType = self.retainInfoModel.voucherType;
    if (vourcherType == CJPayRetainVoucherTypeV1 && Check_ValidString(self.retainInfoModel.voucherContent)) {
        // style 1.0
        CJPayMasMaker(self.subTitleLabel, {
            make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(8);
            make.left.lessThanOrEqualTo(self.containerView).offset(20);
            make.right.lessThanOrEqualTo(self.containerView).offset(-20);
            make.centerX.equalTo(self);
            make.bottom.equalTo(self.topButton.mas_top).offset(-24);
        });
    } else if ([@[@(CJPayRetainVoucherTypeV2), @(CJPayRetainVoucherTypeV3)] containsObject
                :@(vourcherType)] && Check_ValidArray(self.retainInfoModel.retainMsgModels)) {
        // style 2.0 3.0
        [self.containerView addSubview:self.retainVoucherView];
        self.subTitleLabel.hidden = YES;
        self.retainVoucherView.hidden = NO;
        CJPayMasMaker(self.retainVoucherView, {
            make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(20);
            make.left.equalTo(self.containerView).offset(20);
            make.right.equalTo(self.containerView).offset(-20);
            make.bottom.equalTo(self.topButton.mas_top).offset(-24);
        });
        [self.retainVoucherView updateWithRetainMsgModels:self.retainInfoModel.retainMsgModels
                                             vourcherType:vourcherType];
    } else {
        // 无营销
        CJPayMasMaker(self.topButton, {
            make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(24);
        });
    }
    
    if (Check_ValidString(self.retainInfoModel.bottomButtonText)) {
        [self p_setupUIForOtherVerify];
    }
}

- (void)p_setupUIForOtherVerify {
    self.bottomButton.hidden = NO;
    CJPayMasMaker(self.bottomButton, {
        make.centerX.equalTo(self.containerView);
        make.height.mas_equalTo(18);
        make.top.equalTo(self.topButton.mas_bottom).offset(13);
    });
    
    CJPayMasReMaker(self.containerView, {
        make.bottom.equalTo(self.bottomButton.mas_bottom).offset(13);
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
    });
}


#pragma mark - ClickAction
 
- (void)p_closeButtonTapped{
    [self dismissSelfWithCompletionBlock:self.retainInfoModel.closeCompletionBlock];
}

- (void)p_topButtonTapped {
    [self dismissSelfWithCompletionBlock:self.retainInfoModel.topButtonBlock];
}

- (void)p_bottomButtonTapped {
    [self dismissSelfWithCompletionBlock:self.retainInfoModel.bottomButtonBlock];
}

#pragma mark - View

- (CJPayButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [CJPayButton new];
        [_closeButton cj_setImageName:@"cj_close_denoise_icon" forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(p_closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (CJPayButton *)bottomButton {
    if (!_bottomButton) {
        _bottomButton = [CJPayButton new];
        [_bottomButton setTitleColor:[UIColor cj_161823WithAlpha:0.6] forState:UIControlStateNormal];
        [_bottomButton.titleLabel setFont:[UIFont cj_fontOfSize:13]];
        [_bottomButton setTitle:CJString(self.retainInfoModel.bottomButtonText) forState:UIControlStateNormal];
        [_bottomButton addTarget:self action:@selector(p_bottomButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        _bottomButton.hidden = YES;
    }
    return _bottomButton;
}

- (CJPayStyleButton *)topButton{
    if (!_topButton) {
        _topButton = [CJPayStyleButton new];
        _topButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_topButton.titleLabel setTextColor:[UIColor whiteColor]];
        [_topButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        [_topButton setTitle:CJString(self.retainInfoModel.topButtonText) forState:UIControlStateNormal];
        [_topButton addTarget:self action:@selector(p_topButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _topButton;
}

- (UILabel *)mainTitleLabel{
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.text = CJString(self.retainInfoModel.title);
        _mainTitleLabel.font = [UIFont cj_boldFontOfSize:17];
        _mainTitleLabel.textColor = [UIColor cj_161823ff];
        _mainTitleLabel.textAlignment = NSTextAlignmentCenter;
        _mainTitleLabel.numberOfLines = 0;
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel{
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        [self p_initTitleLabelStyle:_subTitleLabel];
        _subTitleLabel.textAlignment = self.isDescTextAlignmentLeft ? NSTextAlignmentLeft : NSTextAlignmentCenter;
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

- (NSMutableAttributedString *)p_stringSeparatedWithDollar:(NSString *)string {
    NSArray * arr = [string componentsSeparatedByString:@"$"];
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paraStyle.alignment = self.isDescTextAlignmentLeft ? NSTextAlignmentLeft : NSTextAlignmentCenter;
    NSDictionary *blackAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor cj_161823WithAlpha:0.75],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSDictionary *orangeAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor cj_colorWithHexString:@"FF6E26"],
                                     NSParagraphStyleAttributeName : paraStyle};
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[arr cj_objectAtIndex:0]?:@"" attributes:blackAttributes];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:1]?:@"" attributes:orangeAttributes]];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:[arr cj_objectAtIndex:2]?:@"" attributes:blackAttributes]];
    return attributedString;
}

- (void)p_initTitleLabelStyle:(UILabel *)titleLabel {
    if (self.retainInfoModel.voucherContent) {
        if ([self.retainInfoModel.voucherContent containsString:@"$"]) {
            NSMutableAttributedString *attributedString = [self p_stringSeparatedWithDollar:self.retainInfoModel.voucherContent];
            [titleLabel setAttributedText:attributedString];
        } else {
            titleLabel.text = self.retainInfoModel.voucherContent;
            titleLabel.font = [UIFont cj_fontOfSize:14];
            titleLabel.textColor = self.retainInfoModel.titleColor ? : [UIColor cj_161823ff];
        }
    } else {
        titleLabel.text = CJPayLocalizedStr(@"");
    }
}

- (CJPayRetainVoucherListView *)retainVoucherView {
    if (!_retainVoucherView) {
        _retainVoucherView = [CJPayRetainVoucherListView new];
        _retainVoucherView.hidden = YES;
    }
    return _retainVoucherView;
}

@end
