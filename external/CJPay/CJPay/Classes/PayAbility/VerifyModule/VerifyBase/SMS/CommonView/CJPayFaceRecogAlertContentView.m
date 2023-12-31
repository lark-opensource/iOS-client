//
//  CJPayFaceRecogAlertContentView.m
//  CJPay
//
//  Created by 尚怀军 on 2020/8/19.
//

#import "CJPayFaceRecogAlertContentView.h"
#import "CJPayUIMacro.h"
#import "UITapGestureRecognizer+CJPay.h"
#import "CJPayWebViewUtil.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayMemAgreementModel.h"
#import "CJPayFaceRecognitionModel.h"

@interface CJPayFaceRecogAlertContentView()

@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UIImageView *faceImageView;
@property (nonatomic, strong) UILabel *subTitleLabel;

@property (nonatomic, strong) CJPayCommonProtocolModel *protocolModel;
@property (nonatomic, copy) void(^protocolClickBlock)(NSArray<CJPayMemAgreementModel *> *agreements, UIViewController *topVC);

@end

@implementation CJPayFaceRecogAlertContentView

+ (NSDictionary *)attributes {
    return [self attributesWithForegroundColor:nil alignment:NSTextAlignmentLeft];
}

+ (NSDictionary *)attributesWithForegroundColor:(nullable UIColor *)foregroundColor alignment:(NSTextAlignment)alignment {
    NSMutableParagraphStyle *paraghStyle = [NSMutableParagraphStyle new];
    paraghStyle.cjMaximumLineHeight = 20;
    paraghStyle.cjMinimumLineHeight = 20;
    paraghStyle.alignment = alignment;
    
    UIColor *color = foregroundColor ? foregroundColor : [UIColor cj_222222ff];
    
    return @{NSFontAttributeName:[UIFont cj_fontOfSize:14],
             NSParagraphStyleAttributeName:paraghStyle,
            NSForegroundColorAttributeName:color};
}

+ (UIColor *)highlightColor {
    return [UIColor cj_colorWithHexString:@"1a74ff"];
}


- (instancetype)initWithProtocolModel:(CJPayCommonProtocolModel *)protocolModel
                             showType:(CJPayFaceRecognitionStyle)type
               shouldShowProtocolView:(BOOL)shouldShowProtocolView
                     protocolDidClick:(void(^)(NSArray<CJPayMemAgreementModel *> *agreements, UIViewController *topVC))protocolDidClick {
    self = [self init];
    if (self) {
        self.protocolModel = protocolModel;
        self.protocolClickBlock = protocolDidClick;
        [self p_setupUIWithType:type shouldShowProtocolView:shouldShowProtocolView];
    }
    return self;
}

- (void)updateWithTitle:(NSString *)title {
    self.mainTitleLabel.text = title;
}

- (void)p_setupUIWithType:(CJPayFaceRecognitionStyle)type shouldShowProtocolView:(BOOL)shouldShowProtocolView {
    [self addSubview:self.faceImageView];
    [self addSubview:self.mainTitleLabel];
    
    CJPayMasMaker(self.faceImageView, {
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(60);
        make.top.equalTo(self).offset(32);
    })
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.top.equalTo(self.faceImageView.mas_bottom).offset(16);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    })
    
    if (type == CJPayFaceRecognitionStyleActivelyArouseInPayment) {
        if (shouldShowProtocolView) {
            [self addSubview:self.protocolView];
            
            CJPayMasMaker(self.protocolView, {
                make.left.equalTo(self).offset(20);
                make.right.lessThanOrEqualTo(self).offset(-20);
                make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(20);
                make.bottom.equalTo(self);
            })
        } else {
            CJPayMasMaker(self.mainTitleLabel, {
                make.bottom.equalTo(self);
            })
        }
        self.mainTitleLabel.text = CJPayLocalizedStr(@"使用刷脸支付");
    } else if (type == CJPayFaceRecognitionStyleOpenBioVerify) {
        [self addSubview:self.subTitleLabel];
        
        CJPayMasMaker(self.subTitleLabel, {
            make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(8);
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.bottom.equalTo(self).offset(-12);
        })
        self.mainTitleLabel.text = CJPayLocalizedStr(@"刷脸验证");
        self.subTitleLabel.text = CJPayLocalizedStr(@"当前功能只有本人才能使用，请确保为本人操作");
        self.subTitleLabel.textAlignment = NSTextAlignmentCenter;
    }  else if (type == CJPayFaceRecognitionStyleExtraTestInPayment) {
        if (shouldShowProtocolView) {
            [self addSubview:self.protocolView];
            
            CJPayMasMaker(self.protocolView, {
                make.left.equalTo(self).offset(20);
                make.right.lessThanOrEqualTo(self).offset(-20);
                make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(20);
                make.bottom.equalTo(self);
            })
        } else {
            CJPayMasMaker(self.mainTitleLabel, {
                make.top.equalTo(self.faceImageView.mas_bottom).offset(16);
                make.left.equalTo(self).offset(20);
                make.right.equalTo(self).offset(-20);
                make.bottom.equalTo(self);
            })
        }
        self.mainTitleLabel.text = CJPayLocalizedStr(@"本次交易需验证本人的人脸信息以确保安全，请完成验证");
    } else if (type == CJPayFaceRecognitionStyleExtraTestInBindCard) {
        if (shouldShowProtocolView) {
            [self addSubview:self.subTitleLabel];
            [self addSubview:self.protocolView];
            
            CJPayMasMaker(self.subTitleLabel, {
                make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(8);
                make.left.equalTo(self).offset(20);
                make.right.equalTo(self).offset(-20);
            })
            
            CJPayMasMaker(self.protocolView, {
                make.left.equalTo(self).offset(20);
                make.right.lessThanOrEqualTo(self).offset(-20);
                make.top.equalTo(self.subTitleLabel.mas_bottom).offset(20);
                make.bottom.equalTo(self);
            })
            
            self.subTitleLabel.textAlignment = NSTextAlignmentLeft;
        } else {
            [self addSubview:self.subTitleLabel];
            
            CJPayMasMaker(self.subTitleLabel, {
                make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(8);
                make.left.equalTo(self).offset(20);
                make.right.equalTo(self).offset(-20);
                make.bottom.equalTo(self).offset(-12);
            })
            
            self.subTitleLabel.textAlignment = NSTextAlignmentCenter;
        }
        self.mainTitleLabel.text = CJPayLocalizedStr(@"刷脸验证");
        self.subTitleLabel.text = CJPayLocalizedStr(@"银行卡绑定仅限本人使用，请进行刷脸验证本人身份");
    }
    if (Check_ValidString(self.protocolModel.title)) {
        self.mainTitleLabel.text = self.protocolModel.title;
    }
    if (Check_ValidString(self.protocolModel.iconUrl)) {
        [self.faceImageView cj_setImageWithURL:[NSURL URLWithString:self.protocolModel.iconUrl]];
        CJPayMasReMaker(self.faceImageView, {
            make.centerX.equalTo(self);
            make.width.height.mas_equalTo(70);
            make.top.equalTo(self).offset(32);
        })
    }
}

#pragma mark - lazy view

- (UIImageView *)faceImageView {
    if (!_faceImageView) {
        _faceImageView = [UIImageView new];
        [_faceImageView cj_setImage:@"cj_face_new_icon"];
    }
    return _faceImageView;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.font = [UIFont cj_boldFontOfSize:17];
        _mainTitleLabel.textColor = [UIColor cj_161823ff];
        _mainTitleLabel.textAlignment = NSTextAlignmentCenter;
        _mainTitleLabel.numberOfLines = 2;
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:14];
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:self.protocolModel];
        _protocolView.protocolClickHandleInBlockOnly = YES;
        @CJWeakify(self)
        _protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.protocolClickBlock, agreements, [self cj_responseViewController]);
        };
    }
    return _protocolView;
}

@end
