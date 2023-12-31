//
//  CJPayBindCardTopHeaderView.m
//  Pods
//
//  Created by renqiang on 2021/6/28.
//

#import "CJPayBindCardTopHeaderView.h"
#import "CJPayUIMacro.h"
#import "CJPayMemBankSupportListResponse.h"
#import "CJPayBindCardTitleInfoModel.h"
#import "CJPayBindCardTopHeaderViewModel.h"
#import "CJPayBindCardManager.h"
#import "CJPaySettingsManager.h"
#import "CJPayVoucherListModel.h"

static const NSInteger kMainTitleViewMargin = 16;
static const NSInteger kMainTitleLineHeight = 35;
static const NSInteger kMainTitleHeightConstraintHighOffset = 70;
static const NSInteger kMainTitleHeightConstraintNormalOffset = 30;

@interface CJPayBindCardTopHeaderView()

#pragma mark - view
@property (nonatomic, strong) UILabel *mainTitleView;
@property (nonatomic, strong) UIImageView *safeImageView;
@property (nonatomic, strong) UILabel *subTitleView;
@property (nonatomic, strong) UIView *normalView;
@property (nonatomic, strong) UILabel *voucherView;
#pragma mark - model
@property (nonatomic, copy) NSString *firstStepMainTitle;
@property (nonatomic, strong) MASConstraint *mainTitleViewHeightConstraint;
@property (nonatomic, strong) MASConstraint *bottomConstraint;

@end

@implementation CJPayBindCardTopHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - private
- (void)p_setupUI {
    [self addSubview:self.mainTitleView];
    [self.normalView addSubview:self.safeImageView];
    [self.normalView addSubview:self.subTitleView];
    [self addSubview:self.normalView];
    [self addSubview:self.voucherView];
    
    CJPayMasMaker(self.mainTitleView, {
        make.top.equalTo(self).offset(16);
        make.centerX.equalTo(self);
        self.mainTitleViewHeightConstraint = make.height.mas_equalTo(kMainTitleHeightConstraintNormalOffset);
        make.left.greaterThanOrEqualTo(self).offset(kMainTitleViewMargin);
        make.right.lessThanOrEqualTo(self).offset(-kMainTitleViewMargin);
    })
    CJPayMasMaker(self.normalView, {
        make.top.equalTo(self.mainTitleView.mas_bottom).offset(4);
        make.centerX.equalTo(self);
        self.bottomConstraint = make.bottom.equalTo(self).offset(-24);
    })
    CJPayMasMaker(self.voucherView, {
        make.top.equalTo(self.normalView);
        make.left.right.equalTo(self);
        make.bottom.greaterThanOrEqualTo(self.normalView);
    })
    CJPayMasMaker(self.safeImageView, {
        make.left.equalTo(self.normalView);
        make.centerY.equalTo(self.normalView);
        make.size.mas_equalTo(CGSizeMake(16, 16));
    })
    CJPayMasMaker(self.subTitleView, {
        make.left.equalTo(self.safeImageView.mas_right).offset(4);
        make.height.mas_equalTo(20);
        make.right.top.bottom.equalTo(self.normalView);
    })
}

- (void)updateWithModel:(CJPayBindCardTopHeaderViewModel *)model {
    [self p_updateMainTitle:model]; // 更新主title文案
    
    if (model.forceShowTopSafe) {
        [self p_updateNormalView:model];
        return;
    }
    
    self.voucherView.hidden = NO;
    self.normalView.hidden = YES;
    
    if (Check_ValidString(model.voucherMsg)) {
        self.voucherView.text = model.voucherMsg;
        return;
    }
    
    if ([self p_shownVocherList:model.voucherList]) {
        return;
    }
    
    [self p_updateNormalView:model]; //更新安全感文案
}

- (BOOL)p_shownVocherList:(CJPayVoucherListModel *)voucherList {
    if (Check_ValidString(voucherList.mixVoucherMsg)) {
        if (![self p_isLabelOmitted:self.voucherView msg:voucherList.mixVoucherMsg]) {
            return YES;
        }
    }
    
    if (Check_ValidString(voucherList.basicVoucherMsg)) {
        self.voucherView.text = voucherList.basicVoucherMsg;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.voucherView.cj_height > 20) { //超过一行
                self.bottomConstraint.offset = -44;
            }
        });
        return YES;
    }
    
    return NO;
}

- (BOOL)p_isLabelOmitted:(UILabel *)label msg:(NSString *)msg {
    label.text = msg;
    CGSize size = [label.text sizeWithAttributes:@{NSFontAttributeName:label.font}];
    if (size.width > label.bounds.size.width) {
        return YES;
    }
    return NO;
}

- (void)p_updateNormalView:(CJPayBindCardTopHeaderViewModel *)model {
    self.normalView.hidden = NO;
    self.voucherView.hidden = YES;
    
    if (Check_ValidString(model.displayIcon)) {
        [self.safeImageView cj_setImageWithURL:[NSURL URLWithString:CJString(model.displayIcon)]];
    }
    
    if (Check_ValidString(model.displayDesc)) {
        self.subTitleView.text = model.displayDesc;
    }
}

- (void)p_updateMainTitle:(CJPayBindCardTopHeaderViewModel *)model {
    if (Check_ValidString(model.bankIcon)) {
        @CJWeakify(self)
        NSAttributedString *mainText = [model getAttributedStringWithCompletion:^(NSMutableAttributedString * _Nullable attributedStr) {
            @CJStrongify(self)
            if (attributedStr) {
                [self p_updateMainTitleViewText:attributedStr];
                [self setNeedsDisplay];
            }
        }];
        [self p_updateMainTitleViewText:mainText];
    } else {
        if ([model.title containsString:@"¥"]) {
            NSArray *stringArray = [model.title componentsSeparatedByString:@" "];
            NSString *title = @"";
            NSString *amount = @"";
            if ([[stringArray cj_objectAtIndex:0] isKindOfClass:[NSString class]]) {
                title = (NSString *)[stringArray cj_objectAtIndex:0];
            }
            if ([[stringArray cj_objectAtIndex:1] isKindOfClass:[NSString class]]) {
                amount = (NSString *)[stringArray cj_objectAtIndex:1];
            }
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            paragraphStyle.minimumLineHeight = 31;
            NSMutableAttributedString *titleStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:CJPayLocalizedStr(@"%@ ") ,title] attributes:@{
                NSFontAttributeName : [UIFont cj_boldFontWithoutFontScaleOfSize:22],
                NSForegroundColorAttributeName : [UIColor cj_161823ff],
                NSParagraphStyleAttributeName:paragraphStyle
            }];
            NSMutableAttributedString *amountStr = [[NSMutableAttributedString alloc]
                initWithString:CJPayLocalizedStr(amount)  attributes:@{
                NSFontAttributeName : [UIFont cj_denoiseBoldFontWithoutFontScaleOfSize:26],
                NSForegroundColorAttributeName : [UIColor cj_161823ff],
                NSParagraphStyleAttributeName:paragraphStyle,
                NSBaselineOffsetAttributeName:@(-1)
            }];
            [attributedString appendAttributedString:titleStr];
            [attributedString appendAttributedString:amountStr];
            self.mainTitleView.attributedText = attributedString;
        } else {
            self.mainTitleView.text = Check_ValidString(model.title) ? model.title : CJPayLocalizedStr(@"添加银行卡");
        }
        self.mainTitleViewHeightConstraint.offset = kMainTitleHeightConstraintNormalOffset;
        self.mainTitleView.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
}

- (void)p_updateMainTitleViewText:(NSAttributedString *)attributedStr {
    self.mainTitleView.attributedText = attributedStr;
    CGSize mainTextBounds = [attributedStr cj_size:(CJ_SCREEN_WIDTH - kMainTitleViewMargin * 2)];
    self.mainTitleView.numberOfLines = 2;
    if (mainTextBounds.height >= kMainTitleLineHeight) {
        self.mainTitleView.lineBreakMode = NSLineBreakByWordWrapping;
        self.mainTitleViewHeightConstraint.offset = kMainTitleHeightConstraintHighOffset;
    } else {
        self.mainTitleView.lineBreakMode = NSLineBreakByTruncatingMiddle;
        self.mainTitleViewHeightConstraint.offset = kMainTitleHeightConstraintNormalOffset;
    }
}

#pragma mark - lazy view
- (UILabel *)mainTitleView {
    if (!_mainTitleView) {
        _mainTitleView = [UILabel new];
        _mainTitleView.font = [UIFont cj_boldFontWithoutFontScaleOfSize:22];
        _mainTitleView.textColor = [UIColor cj_161823ff];
        _mainTitleView.textAlignment = NSTextAlignmentCenter;
    }
    return _mainTitleView;
}

- (UILabel *)subTitleView {
    if (!_subTitleView) {
        _subTitleView = [UILabel new];
        _subTitleView.text = CJPayLocalizedStr(@"中国人保财险提供百万保障");
        _subTitleView.font = [UIFont cj_fontOfSize:14];
        _subTitleView.textColor = [UIColor cj_161823WithAlpha:0.75];
    }
    return _subTitleView;
}

- (UIImageView *)safeImageView {
    if (!_safeImageView) {
        _safeImageView = [UIImageView new];
        [_safeImageView cj_setImage:@"cj_safe_blue_icon"];
    }
    return _safeImageView;
}

- (UIView *)normalView {
    if (!_normalView) {
        _normalView = [UIView new];
    }
    return _normalView;
}

- (UILabel *)voucherView {
    if (!_voucherView) {
        _voucherView = [UILabel new];
        _voucherView.textColor = [UIColor cj_fe2c55ff];
        _voucherView.font = [UIFont cj_boldFontOfSize:14];
        _voucherView.numberOfLines = 0;
        _voucherView.hidden = YES;
        _voucherView.textAlignment = NSTextAlignmentCenter;
    }
    return _voucherView;
}

@end
