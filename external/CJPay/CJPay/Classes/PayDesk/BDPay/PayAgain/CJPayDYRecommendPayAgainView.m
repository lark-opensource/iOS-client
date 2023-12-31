//
//  CJPayDYRecommendPayAgainView.m
//  Pods
//
//  Created by wangxiaohong on 2022/3/23.
//

#import "CJPayDYRecommendPayAgainView.h"

#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayThemeStyleManager.h"

@interface CJPayDYRecommendPayAgainView()

@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmButtton;
@property (nonatomic, strong) CJPayLoadingButton *otherPayButton;


@end

@implementation CJPayDYRecommendPayAgainView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)refreshWithHintInfo:(CJPayHintInfo *)hintInfo {
    self.titleLabel.text = CJString(hintInfo.statusMsg);
    [self.confirmButtton cj_setBtnTitle:CJString(hintInfo.buttonText)];
    [self.otherPayButton cj_setBtnTitle:CJString(hintInfo.subButtonText)];
    
    CJPayChannelType channelType = hintInfo.recPayType.channelType;
    if (channelType == BDPayChannelTypeAddBankCard) { //添加新卡
        self.otherPayButton.hidden = YES;
        self.subTitleLabel.text = hintInfo.subStatusMsg;
    } else if (channelType == BDPayChannelTypeBalance || channelType == BDPayChannelTypeBankCard) { // 老卡|余额
        self.otherPayButton.hidden = NO;
        [self p_asyncRefreshLabelWithHintInfoModel:hintInfo];
        self.subTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
}

- (void)p_setupUI {
    [self addSubview:self.logoImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.confirmButtton];
    [self addSubview:self.otherPayButton];
    
    CJPayMasMaker(self.logoImageView, {
        make.top.equalTo(self).offset(80);
        make.width.height.mas_equalTo(60);
        make.centerX.equalTo(self);
    });
    self.logoImageView.layer.cornerRadius = 40;
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(16);
        make.centerX.equalTo(self);
        make.left.right.lessThanOrEqualTo(self).inset(24);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(12);
        make.centerX.equalTo(self);
        make.left.right.lessThanOrEqualTo(self).inset(24);
    })
    
    CJPayMasMaker(self.otherPayButton, {
        make.top.equalTo(self.confirmButtton.mas_bottom).offset(13);
        make.height.mas_equalTo(18);
        make.bottom.equalTo(self).offset(-13);
        make.left.right.equalTo(self).inset(24);
    });
    
    CJPayMasMaker(self.confirmButtton, {
        make.bottom.equalTo(self.otherPayButton.mas_top).offset(-13);
        make.left.right.equalTo(self.otherPayButton);
        make.height.mas_equalTo(44);
    });
}

- (void)p_asyncRefreshLabelWithHintInfoModel:(CJPayHintInfo *)hintInfo { //图文混排耗时，异步刷新避免卡顿
    dispatch_queue_t processQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(processQueue, ^{
        NSAttributedString *attributStr = [self p_attrStringWithText:CJString(hintInfo.recPayType.title) imageStr:hintInfo.recPayType.iconUrl];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.subTitleLabel.attributedText = attributStr;
        });
    });
}

// 实现图文混排
- (NSAttributedString *)p_attrStringWithText:(NSString *)text imageStr:(NSString *)imageStr {
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageStr]]];
    attachment.bounds = CGRectMake(0, -2, 16, 16);
    
    NSAttributedString *imageAttr = [NSAttributedString attributedStringWithAttachment:attachment];
    
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    NSDictionary *attributes = @{
        NSFontAttributeName:[UIFont systemFontOfSize:15],
        NSParagraphStyleAttributeName:paragraphStyle,
    };
    
    NSAttributedString *preTextAttr = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(@"可更换为 ") attributes:attributes];
    NSAttributedString *textAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:CJPayLocalizedStr(@" %@ 继续支付"), text] attributes:attributes];

    NSMutableAttributedString *mutableAttr = [[NSMutableAttributedString alloc] init];
    [mutableAttr appendAttributedString:preTextAttr];
    [mutableAttr appendAttributedString:imageAttr];
    [mutableAttr appendAttributedString:textAttr];
    
    NSRange range = [mutableAttr.string rangeOfString:imageAttr.string]; //获取图片位置
    NSRange imageRange = NSMakeRange(range.location, range.length + 1); //增加一个空格用来控制图文间距
    [mutableAttr addAttribute:NSKernAttributeName value:@(-1) range:imageRange];
    
    return [mutableAttr copy];
}

#pragma mark - Lazy Views

- (UIImageView *)logoImageView {
    if (!_logoImageView) {
        _logoImageView = [UIImageView new];
        [_logoImageView cj_setImage:@"cj_error_hollow_icon"];
        _logoImageView.backgroundColor = [CJPayThemeStyleManager shared].serverTheme.checkBoxStyle.backgroundColor;
    }
    return _logoImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:14];
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
        _subTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

- (CJPayStyleButton *)confirmButtton {
    if (!_confirmButtton) {
        _confirmButtton = [CJPayStyleButton new];
        _confirmButtton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmButtton.titleLabel.textColor = [UIColor whiteColor];
    }
    return _confirmButtton;
}

- (CJPayLoadingButton *)otherPayButton {
    if (!_otherPayButton) {
        _otherPayButton = [CJPayLoadingButton new];
        [_otherPayButton cj_setBtnTitleColor:[UIColor cj_161823ff]];
        _otherPayButton.titleLabel.font = [UIFont cj_boldFontOfSize:13];
    }
    return _otherPayButton;
}

@end
