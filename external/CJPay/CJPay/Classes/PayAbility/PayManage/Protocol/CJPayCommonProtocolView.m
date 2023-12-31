//
//  CJPayCommonProtocolView.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/5.
//

#import "CJPayCommonProtocolView.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayStyleCheckBox.h"
#import "CJPayCommonProtocolModel.h"
#import "UITapGestureRecognizer+CJPay.h"
#import "CJPayProtocolListViewController.h"
#import "CJPayProtocolDetailViewController.h"
#import "CJPayThemeStyleManager.h"
#import "CJPaySwitch.h"
#import "CJPayFullPageBaseViewController.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayToast.h"

@interface CJPayCommonProtocolView()

@property (nonatomic, strong) CJPayStyleCheckBox *checkBox;
@property (nonatomic, strong) CJPaySwitch *switchButton;
@property (nonatomic, strong) UILabel *textLabel;

@property (nonatomic, strong) CJPayCommonProtocolModel *protocolModel;


@end

@implementation CJPayCommonProtocolView

- (instancetype)initWithCommonProtocolModel:(CJPayCommonProtocolModel *)protocolModel {
    self = [self init];
    if (self) {
        _protocolModel = protocolModel;
        [self p_setupUI];
    }
    return self;
}

- (BOOL)isCheckBoxSelected {
    return self.checkBox.isSelected || self.switchButton.isOn;
}

- (void)setCheckBoxSelected:(BOOL)isSelected {
    self.checkBox.selected = isSelected;
    [self.switchButton setOn:isSelected];
}

- (void)setProtocolDetailContainerHeight:(CGFloat)viewHeight {
    if(viewHeight > 0) {
        self.protocolModel.protocolDetailContainerHeight = @(viewHeight);
    }
}

- (void)p_setupUI {
    [self addSubview:self.checkBox];
    [self addSubview:self.textLabel];
    [self addSubview:self.switchButton];
    [self p_setAgreeStatus:self.protocolModel.isSelected];
    
    [self p_updateViewsConstraint];
    [self p_updateProtocolContent];
}

- (void)updateWithCommonModel:(CJPayCommonProtocolModel *)commonModel {
    self.protocolModel = commonModel;
    [self p_setAgreeStatus:self.protocolModel.isSelected];
    
    [self p_updateViewsConstraint];
    [self p_updateProtocolContent];
}

- (void)p_updateViewsConstraint {
    switch (self.protocolModel.selectPattern) {
        case CJPaySelectButtonPatternCheckBox:
            self.checkBox.hidden = NO;
            self.switchButton.hidden = YES;
            
            CJPayMasReMaker(self.checkBox, {
                make.left.equalTo(self);
                if (self.protocolModel.isHorizontalCenterLayout) {
                    make.centerY.equalTo(self.textLabel);
                } else {
                    make.top.equalTo(self).offset(CJ_SIZE_FONT_SAFE(3));
                }
                make.width.height.mas_equalTo(CJ_SIZE_FONT_SAFE(16));
            });
            
            CJPayMasReMaker(self.textLabel, {
                make.left.equalTo(self.checkBox.mas_right).offset(6);
                make.right.equalTo(self);
                make.top.equalTo(self);
                make.bottom.equalTo(self);
            });
            break;
        case CJPaySelectButtonPatternSwitch:
            self.checkBox.hidden = YES;
            self.switchButton.hidden = NO;
            
            CJPayMasReMaker(self.switchButton, {
                make.centerY.equalTo(self);
                make.right.equalTo(self);
                if (self.protocolModel.isHorizontalCenterLayout) {
                    make.width.mas_equalTo(24);
                    make.height.mas_equalTo(14);
                } else {
                    make.width.mas_equalTo(43);
                    make.height.mas_equalTo(25);
                }
            });
            CJPayMasReMaker(self.textLabel, {
                make.left.equalTo(self);
                make.top.equalTo(self);
                make.bottom.equalTo(self);
                make.right.equalTo(self.switchButton.mas_left).offset(self.protocolModel.isHorizontalCenterLayout? -16: -12);
            });
            break;
        default:
            self.checkBox.hidden = YES;
            self.switchButton.hidden = YES;
            CJPayMasReMaker(self.textLabel, {
                make.edges.equalTo(self);
            });
            break;
    }
}

- (UIView *)getClickBtnView {
    UIView *clickBtn = nil;
    switch (self.protocolModel.selectPattern) {
        case CJPaySelectButtonPatternSwitch:
            clickBtn = self.switchButton;
            break;
        case CJPaySelectButtonPatternCheckBox:
            clickBtn = self.checkBox;
            break;
        default:
            break;
    }
    if (!clickBtn || clickBtn.superview != self) {
        return nil;
    }
    return clickBtn;
}

- (void)executeWhenProtocolSelected:(void(^)(void))actionBlock {
    [self executeWhenProtocolSelected:actionBlock
                           notSeleted:nil
                             hasToast:YES];
}

- (void)executeWhenProtocolSelected:(void(^)(void))actionBlock
                         notSeleted:(nullable void(^)(void))notSeletedBlock
                            hasToast:(BOOL)isToast {
    if ([self isCheckBoxSelected] || (self.checkBox.hidden && self.switchButton.hidden)) {
        CJ_CALL_BLOCK(actionBlock);
    } else {
        if (isToast) {
            [CJToast toastText:CJPayLocalizedStr(@"请先勾选协议") inWindow:self.window];
        }
        CJ_CALL_BLOCK(notSeletedBlock);
    }
}

- (void)p_updateProtocolContent {
    CGFloat lineHeight = self.protocolModel.protocolLineHeight ?: 20;
    UIFont *protocolFont = self.protocolModel.protocolFont ?: [UIFont cj_fontOfSize:12];
    UIColor *protocolColor = self.protocolModel.protocolColor ?: [UIColor cj_161823WithAlpha:0.75];
    NSTextAlignment textAlignment = self.protocolModel.protocolTextAlignment;
    UIColor *jumpColor = self.protocolModel.protocolJumpColor ?: ([CJPayThemeStyleManager shared].serverTheme.agreementTextColor ?: [UIColor cj_douyinBlueColor]);
    
    NSMutableParagraphStyle *paraghStyle = [NSMutableParagraphStyle new];
    paraghStyle.cjMaximumLineHeight = lineHeight;
    paraghStyle.cjMinimumLineHeight = lineHeight;
    paraghStyle.alignment = textAlignment;
    
    NSDictionary *attributes = @{NSFontAttributeName:protocolFont,
                       NSParagraphStyleAttributeName:paraghStyle,
                      NSForegroundColorAttributeName:protocolColor};
    
    NSMutableAttributedString *protocolStr = [[NSMutableAttributedString alloc] initWithString:CJString(self.protocolModel.guideDesc) attributes:attributes];
    
    NSDictionary *jumpAttributes = @{NSFontAttributeName:protocolFont,
                           NSParagraphStyleAttributeName:paraghStyle,
                          NSForegroundColorAttributeName:jumpColor};
    
    NSUInteger groupCount = self.protocolModel.groupNameDic.allValues.count;
    
    [self.protocolModel.groupNameDic.allValues enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidString(obj)) {
            if (![obj hasPrefix:@"《"]) {
                obj = [NSString stringWithFormat:@" %@", obj];
            }
            if (idx > 0 && idx < groupCount) {
                [protocolStr appendAttributedString:[self p_getSeparateAtributeStrWithAttributes:jumpAttributes]];
            }
            NSAttributedString *jumpStr = [[NSAttributedString alloc] initWithString:obj
                                                                          attributes:jumpAttributes];
    
            [protocolStr appendAttributedString:jumpStr];
        }
    }];
    
//    [protocolStr appendAttributedString:[self p_getSpaceAtributeStr]];
    if (Check_ValidString(self.protocolModel.tailText)) {
        [protocolStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"，" attributes:attributes]];
        [protocolStr appendAttributedString:[[NSAttributedString alloc] initWithString:self.protocolModel.tailText attributes:attributes]];
    }
    self.textLabel.attributedText = protocolStr;
}

- (void)protocolLabelTapped:(UITapGestureRecognizer *)tapGesture {
    
    NSString *groupId = [self p_getSelectGroupWithTapGesture:tapGesture];
    if (!Check_ValidString(groupId)) {
        //没有找到点击的协议组，直接返回
        return;
    }
    
    [self p_gotoProtocolDetailVCWithAgreements:[self p_getAgreementsWithGroupId:groupId]];
}

- (NSAttributedString *)p_getSeparateAtributeStrWithAttributes:(NSDictionary *)attributes {
    return [[NSAttributedString alloc] initWithString:@"、" attributes:attributes];
}

- (NSAttributedString *)p_getSpaceAtributeStr {
    return [[NSAttributedString alloc] initWithString:@" " attributes:nil];
}

- (NSString *)p_getSelectGroupWithTapGesture:(UITapGestureRecognizer *)tapGesture {
    if (!self.protocolModel.groupNameDic || self.protocolModel.groupNameDic.count == 0) {
        return @"";
    }
    
    __block NSString *selectGroupId = @"";
    [self.protocolModel.groupNameDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj && key) {
            NSRange groupRange = [self.textLabel.attributedText.string rangeOfString:obj];
            BOOL isClickProtocolGroup = [tapGesture cj_didTapAttributedTextInLabel:self.textLabel
                                                                           inRange:groupRange];
            if (isClickProtocolGroup) {
                selectGroupId = key;
                *stop = YES;
            }
        }
    }];
    
    return selectGroupId;
}

- (NSArray<CJPayQuickPayUserAgreement *> *)p_getAgreementsWithMemAgreeList:(NSArray<CJPayMemAgreementModel *> *)memAgreeList {
    NSMutableArray *agreements = [NSMutableArray array];
    [memAgreeList enumerateObjectsUsingBlock:^(CJPayMemAgreementModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [agreements addObject:[obj toQuickPayUserAgreement]];
    }];
    return agreements;
}

- (NSArray<CJPayMemAgreementModel *> *)p_getAgreementsWithGroupId:(NSString *)groupId {
    NSMutableArray *agreements = [NSMutableArray array];
    [self.protocolModel.agreements enumerateObjectsUsingBlock:^(CJPayMemAgreementModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.group isEqualToString:groupId]) {
            [agreements addObject:obj];
        }
    }];
    return agreements;
}

- (void)p_gotoProtocolDetailVCWithAgreements:(NSArray<CJPayMemAgreementModel *> *)agreements {
    if (agreements.count <= 0) {
        return;
    }
    
    CJ_CALL_BLOCK(self.protocolClickBlock, agreements);

    if (self.protocolClickHandleInBlockOnly) {
        return;
    }
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    NSArray<CJPayQuickPayUserAgreement *> *quickAgreeList = [self p_getAgreementsWithMemAgreeList:agreements];
    CJPayHalfPageBaseViewController * tmpVC = [CJPayProtocolViewManager createProtocolViewController:quickAgreeList protocolModel:self.protocolModel];

    if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        tmpVC.animationType = HalfVCEntranceTypeFromRight;
        [tmpVC showMask:NO];
    } else {
        [tmpVC showMask:![topVC isKindOfClass:CJPayPopUpBaseViewController.class]];
        [tmpVC useCloseBackBtn];
        tmpVC.animationType = HalfVCEntranceTypeFromBottom;
    }
    [topVC.navigationController pushViewController:tmpVC animated:YES];
}

- (void)p_setAgreeStatus:(BOOL)isAgree {
    self.checkBox.selected = isAgree;
    self.switchButton.on = isAgree;
    self.checkBox.accessibilityLabel = isAgree ? @"勾选框,已勾选" : @"勾选框,未勾选";
    self.switchButton.accessibilityLabel = isAgree ? @"开启按钮,已开启" : @"开启按钮,未开启";
}

- (void)agreeCheckBoxTapped {
    self.checkBox.selected = !self.checkBox.isSelected;
    self.switchButton.on = !self.switchButton.isOn;
    self.checkBox.accessibilityLabel = self.checkBox.selected ? @"勾选框,已勾选" : @"勾选框,未勾选";
    self.switchButton.accessibilityLabel = self.switchButton.on ? @"开启按钮,已开启" : @"开启按钮,未开启";
    CJ_CALL_BLOCK(self.checkBoxClickBlock);
}

- (CJPayStyleCheckBox *)checkBox {
    if (!_checkBox) {
        _checkBox = [[CJPayStyleCheckBox alloc] init];
        _checkBox.clipsToBounds = YES;
        _checkBox.layer.cornerRadius = 8;
        [_checkBox updateWithCheckImgName:@"cj_front_select_card_icon"
                           noCheckImgName:@"cj_noselect_icon"];
        UITapGestureRecognizer *tapGesture= [[UITapGestureRecognizer alloc]initWithTarget:self
                                                                                   action:@selector(agreeCheckBoxTapped)];
        [_checkBox addGestureRecognizer:tapGesture];
        _checkBox.accessibilityLabel = _checkBox.selected ? @"勾选框,已勾选" : @"勾选框,未勾选";
        _checkBox.accessibilityTraits = UIAccessibilityTraitStaticText;
    }
    return _checkBox;
}

- (CJPaySwitch *)switchButton {
    if (!_switchButton) {
        _switchButton = [CJPaySwitch new];
        [_switchButton addTarget:self action:@selector(agreeCheckBoxTapped) forControlEvents:UIControlEventValueChanged];
        _switchButton.accessibilityLabel = _switchButton.on ? @"开启按钮,已开启" : @"开启按钮,未开启";
        _switchButton.accessibilityTraits = UIAccessibilityTraitStaticText;
    }
    return _switchButton;
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.numberOfLines = 0;
        _textLabel.userInteractionEnabled = YES;
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(protocolLabelTapped:)];
        
        [_textLabel addGestureRecognizer:tapGesture];
        [_textLabel setContentHuggingPriority:UILayoutPriorityRequired
                                      forAxis:UILayoutConstraintAxisVertical];
        [_textLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                    forAxis:UILayoutConstraintAxisVertical];
    }
    return _textLabel;
}
@end
