//
//  CJPayHalfVerifySMSHelpViewController.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/26.
//

#import "CJPayHalfVerifySMSHelpViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"

@implementation CJPayVerifySMSHelpModel

@end

@interface CJPayHalfVerifySMSHelpViewController ()

@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;

@end

@implementation CJPayHalfVerifySMSHelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationBar setTitle:CJPayLocalizedStr(@"收不到验证码？")];
    
    [self.contentView addSubview:self.mainTitleLabel];
    [self.contentView addSubview:self.subTitleLabel];
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.left.equalTo(self.mainTitleLabel.superview).offset(16);
        make.right.equalTo(self.mainTitleLabel.superview).offset(-16);
        make.top.equalTo(self.mainTitleLabel.superview).offset(20);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.left.equalTo(self.subTitleLabel.superview).offset(16);
        make.right.equalTo(self.subTitleLabel.superview).offset(-16);
        make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(10);
    });
    
    NSString *tailStr = @"";
    if (self.helpModel.frontBankCodeName.length > 3) {
        tailStr = [self.helpModel.cardNoMask substringFromIndex: self.helpModel.cardNoMask.length - 4];
    }
    
    NSMutableParagraphStyle *mainParaStyle = [NSMutableParagraphStyle new];
    mainParaStyle.cjMaximumLineHeight = 26;
    mainParaStyle.cjMinimumLineHeight = 26;
    
    NSDictionary *mainWeakAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:16],
                                           NSForegroundColorAttributeName : [UIColor cj_222222ff],
                                           NSParagraphStyleAttributeName : mainParaStyle};
    NSMutableAttributedString *mainTitleStr;
    if (Check_ValidString(self.helpModel.phoneNum) && Check_ValidString(self.helpModel.frontBankCodeName) && Check_ValidString(tailStr)) {
        mainTitleStr = [[NSMutableAttributedString  alloc] initWithString:[NSString stringWithFormat:CJPayLocalizedStr(@"请确认%@是%@(%@)的预留手机号码"), CJString(self.helpModel.phoneNum),CJString(self.helpModel.frontBankCodeName), CJString(tailStr)] attributes:mainWeakAttributes];
    } else if (Check_ValidString(self.helpModel.phoneNum)) {
        mainTitleStr = [[NSMutableAttributedString  alloc] initWithString:[NSString stringWithFormat:CJPayLocalizedStr(@"请确认%@是你本人手机号"), CJString(self.helpModel.phoneNum)] attributes:mainWeakAttributes];
    } else {
        mainTitleStr = [[NSMutableAttributedString  alloc] initWithString:CJPayLocalizedStr(@"请确认你的手机号正常使用") attributes:mainWeakAttributes];
    }
    self.mainTitleLabel.attributedText = mainTitleStr;
    
    NSMutableParagraphStyle *subParaStyle = [NSMutableParagraphStyle new];
    subParaStyle.cjMaximumLineHeight = 24;
    subParaStyle.cjMinimumLineHeight = 24;
    
    NSDictionary *subsAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],
                                          NSForegroundColorAttributeName : [UIColor cj_505050ff],
                                          NSParagraphStyleAttributeName : subParaStyle};
    NSString *subText = CJPayLocalizedStr(@"你还可以尝试：\n1、确认短信是否被手机安全软件拦截或被折叠隐藏；\n2、查看手机网络状况是否良好，是否可以正常接收其他号码短信；\n3、若该手机号已经停用，建议换一张卡或联系银行更新预留手机号；\n4、若该卡的预留手机号码已在银行变更，建议你更新该手机号码。");
    NSAttributedString *subAttrStr = [[NSAttributedString alloc] initWithString:CJString(subText) attributes:subsAttributes];
    self.subTitleLabel.attributedText = subAttrStr;
    
}

- (CGFloat)containerHeight {
    if (self.designContentHeight > CGFLOAT_MIN) {
        return self.designContentHeight;
    }
    return [super containerHeight];
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [[UILabel alloc] init];
        _mainTitleLabel.numberOfLines = 0;
    }
    return _mainTitleLabel;
}


- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.numberOfLines = 0;
        _subTitleLabel.lineBreakMode = NSLineBreakByCharWrapping;
    }
    return _subTitleLabel;
}


@end
