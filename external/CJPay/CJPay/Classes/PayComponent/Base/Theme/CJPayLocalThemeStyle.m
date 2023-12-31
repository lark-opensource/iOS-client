//
//  CJPayLocalThemeStyle.m
//  Pods
//
//  Created by 王新华 on 2020/12/4.
//

#import "CJPayLocalThemeStyle.h"
#import "CJPayUIMacro.h"

#define CJPAYISLIGHT (self.themeStyleType == CJPayLocalThemeStyleLight)

@interface CJPayLocalThemeStyle()

@property (nonatomic, strong, readwrite) UIColor *addBankButtonIconBackgroundColor;

@property (nonatomic, readwrite, strong) UIColor *mainBackgroundColor;

@property (nonatomic, readwrite, strong) UIColor *navigationBarBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *navigationBarTitleColor;
@property (nonatomic, readwrite, copy) NSString *navigationBarMoreImageName;
@property (nonatomic, readwrite, strong) UIImage *navigationBarBackButtonImage;
@property (nonatomic, readwrite, nullable) UIColor *navigationLeftButtonTintColor;

@property (nonatomic, readwrite, strong) UIColor *separatorColor;
@property (nonatomic, readwrite, strong) UIColor *titleColor;
@property (nonatomic, readwrite, strong) UIColor *subtitleColor;
@property (nonatomic, readwrite, strong) UIColor *limitTextColor;
@property (nonatomic, readwrite, strong) UIColor *textFieldPlaceHolderColor;

@property (nonatomic, readwrite, strong) UIColor *addBankButtonBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *addBankBigButtonBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *syncUnionCellDivideBackgroundColor;
@property (nonatomic, readwrite, assign) CGFloat syncUnionCellBorderWidth;
@property (nonatomic, readwrite, strong) UIColor *addBankButtonTitleColor;
@property (nonatomic, readwrite, strong) UIColor *addBankButtonBorderColor;
@property (nonatomic, readwrite, copy) NSString *addBankButtonIconImageName;
@property (nonatomic, readwrite, strong) UIColor *addBankButtonNormalTitleColor;
@property (nonatomic, readwrite, copy) NSString *addBankButtonNormalArrowImageName;

@property (nonatomic, readwrite, strong) UIColor *bankActivityMainTitleColor;
@property (nonatomic, readwrite, strong) UIColor *bankActivitySubTitleColor;
@property (nonatomic, readwrite, strong) UIColor *bankActivityBorderColor;
@property (nonatomic, readwrite, strong) UIColor *dyNumberBorderColor;

@property (nonatomic, readwrite, strong) UIColor *faqTextColor;
@property (nonatomic, readwrite, strong) UIColor *unbindCardTextColor;
@property (nonatomic, readwrite, copy) NSString *unbindCardArrowImageName;

@property (nonatomic, readwrite, strong) UIColor *keyBoardBgColor;

@property (nonatomic, readwrite, copy) NSString *inputClearImageStr;

@property (nonatomic, readwrite, strong) UIColor *safeBannerBGColor;
@property (nonatomic, readwrite, strong) UIColor *safeBannerTextColor;

@property (nonatomic, readwrite, strong) UIColor *rechargeCardTitleTextColor;
@property (nonatomic, readwrite, strong) UIColor *rechargeTitleTextColor;
@property (nonatomic, readwrite, strong) UIColor *rechargeContentTextColor;
@property (nonatomic, readwrite, strong) UIColor *rechargeResultTextColor;
@property (nonatomic, readwrite, strong) UIColor *rechargeLinkTextColor;
@property (nonatomic, readwrite, strong) UIColor *rechargeBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *rechargeResultStateTextColor;
@property (nonatomic, readwrite, strong) UIColor *rechargeResultStateTextColorV2;
@property (nonatomic, readwrite, copy) NSString *rechargeSuccessIconName;
@property (nonatomic, readwrite, copy) NSString *rechargeProcessIconName;
@property (nonatomic, readwrite, strong) UIColor *rechargeCopyButtonColor;
@property (nonatomic, readwrite, strong) UIColor *rechargeCompletionButtonBgColor;

@property (nonatomic, readwrite, copy) NSString *resultSuccessIconName;
@property (nonatomic, readwrite, copy) NSString *resultProcessIconName;
@property (nonatomic, readwrite, copy) NSString *resultFailIconName;

@property (nonatomic, readwrite, strong) UIColor *payRechargeViewbackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *payRechargeViewTextColor;
@property (nonatomic, readwrite, strong) UIColor *payRechargeViewSubTextColor;
@property (nonatomic, readwrite, strong) UIColor *payRechargeMainViewTopLineColor;
@property (nonatomic, readwrite, strong) UIColor *payRechargeMainViewShadowsColor;
@property (nonatomic, readwrite, strong) UIColor *payRechargeMainViewShadowsColorV2;
@property (nonatomic, readwrite, strong) UIColor *rechargeMainViewBackgroundColor;

@property (nonatomic, readwrite, strong) UIColor *withdrawTitleTextColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawAmountTextColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawSubTitleTextColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawSubTitleTextColorV2;
@property (nonatomic, readwrite, strong) UIColor *withdrawBlockedProcessBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawDoneProcessBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawUpcomingProcessBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawUpcomingTextColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawArrivingViewBottomLineColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawHeaderViewBottomLineColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawProcessViewTopLineColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawBackgroundColorV2;
@property (nonatomic, readwrite, strong) UIColor *withdrawResultBottomTitleTextColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawResultBottomDetailTextColor;
@property (nonatomic, readwrite, copy) NSString *withdrawResultIconImageTwoName;
@property (nonatomic, readwrite, copy) NSString *withdrawResultIconImageThreeName;
@property (nonatomic, readwrite, strong) UIColor *withdrawResultHeaderTitleTextColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawSegmentBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *withDrawAllbtnTextColor;
@property (nonatomic, readwrite, copy) NSString *withdrawArrowImageName;
@property (nonatomic, readwrite, strong) UIColor *withdrawLimitTextColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawLimitTextColorV2;
@property (nonatomic, readwrite, strong) UIColor *withDrawNoticeViewBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *withDrawNoticeViewTextColor;
@property (nonatomic, readwrite, strong) UIColor *withDrawNoticeViewHornTintColor;

@property (nonatomic, readwrite, strong) UIColor *withDrawRecordbtnTextColor;
@property (nonatomic, readwrite, strong) UIColor *withdrawServiceTextColor;

@property (nonatomic, readwrite, strong) UIColor *drawBalanceSrcollViewBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *drawBalanceSrcollViewTextColor;
@property (nonatomic, readwrite, strong) UIColor *promotionTagColor;

@property (nonatomic, readwrite, strong) UIColor *quickBindCardTitleTextColor;
@property (nonatomic, readwrite, strong) UIColor *quickBindCardDescTextColor;
@property (nonatomic, readwrite, strong) UIColor *quickBindCardBorderColor;
@property (nonatomic, readwrite, copy) NSString *quickBindCardRightArrowImgName;

// 金额键盘主题适配
@property (nonatomic, readwrite, copy) UIColor *amountKeyboardButtonColor;
@property (nonatomic, readwrite, copy) UIColor *amountKeyboardBgColor;
@property (nonatomic, readwrite, copy) UIColor *amountKeyboardTitleColor;
@property (nonatomic, readwrite, copy) UIColor *amountKeyboardButtonSelectColor;
@property (nonatomic, readwrite, copy) NSString *amountKeyboardDeleteIcon;
@property (nonatomic, readwrite, copy) NSString *amountKeyboardTopBgColor;

//自定义键盘主题适配
@property (nonatomic, readwrite, copy) NSString *deleteImageName;
@property (nonatomic, readwrite, strong) UIColor *fontColor;
@property (nonatomic, readwrite, strong) UIColor *borderColor;
@property (nonatomic, readwrite, strong) UIColor *gridBlankBackgroundColor;
@property (nonatomic, readwrite, strong) UIColor *gridNormalColor;
@property (nonatomic, readwrite, strong) UIColor *gridHighlightColor;
@property (nonatomic, readwrite, strong) UIColor *deleteNormalColor;
@property (nonatomic, readwrite, strong) UIColor *deleteHighlightColor;

#pragma mark - flag
@property (nonatomic, assign) CJPayLocalThemeStyleType themeStyleType;

@end

@implementation CJPayLocalThemeStyle

+ (CJPayLocalThemeStyle *)lightThemeStyle {
    static CJPayLocalThemeStyle *themeStyle;
    
    if (themeStyle) {
        return themeStyle;
    }
    
    themeStyle = [CJPayLocalThemeStyle new];
    themeStyle.themeStyleType = CJPayLocalThemeStyleLight;
    
    return themeStyle;
}

+ (CJPayLocalThemeStyle *)darkThemeStyle {
    static CJPayLocalThemeStyle *themeStyle;
    
    if (themeStyle) {
        return themeStyle;
    }
    
    themeStyle = [CJPayLocalThemeStyle new];
    themeStyle.themeStyleType = CJPayLocalThemeStyleDark;
    
    return themeStyle;
}

+ (CJPayLocalThemeStyle *)defaultThemeStyle {
    return [self lightThemeStyle];
}

+ (void)updateStyleBy:(CJPayServerThemeStyle *)themeStyle {
    CJPayLocalThemeStyle *lightThemeStyle = [self lightThemeStyle];
    lightThemeStyle.addBankButtonIconBackgroundColor = themeStyle.checkBoxStyle.backgroundColor ?: [UIColor cj_ff4e33ff];
}

#pragma mark - lazy load
- (UIColor *)mainBackgroundColor {
    if (!_mainBackgroundColor) {
        _mainBackgroundColor = CJPAYISLIGHT ? [UIColor cj_ffffffWithAlpha:1] : [UIColor cj_161823ff];
    }
    return _mainBackgroundColor;
}

- (UIColor *)separatorColor {
    if (!_separatorColor) {
        _separatorColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.12] : [UIColor cj_ffffffWithAlpha:0.08];
    }
    return _separatorColor;
}

- (UIColor *)titleColor {
    if (!_titleColor) {
        _titleColor = CJPAYISLIGHT ? [UIColor cj_colorWithHexString:@"#222222" alpha:1] : [UIColor cj_ffffffWithAlpha:1];
    }
    return _titleColor;
}

- (UIColor *)subtitleColor {
    if (!_subtitleColor) {
        _subtitleColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_ffffffWithAlpha:0.5];
    }
    return _subtitleColor;
}

- (UIColor *)limitTextColor {
    if (!_limitTextColor) {
        _limitTextColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:1];
    }
    return _limitTextColor;
}

- (UIColor *)textFieldPlaceHolderColor {
    if (!_textFieldPlaceHolderColor) {
        _textFieldPlaceHolderColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.34] : [UIColor cj_ffffffWithAlpha:0.34];
    }
    return _textFieldPlaceHolderColor;
}

- (NSString *)inputClearImageStr {
    if (!_inputClearImageStr) {
        _inputClearImageStr = CJPAYISLIGHT ? @"cj_clear_light_icon" : @"cj_clear_dark_icon";
    }
    return _inputClearImageStr;
}

- (UIColor *)safeBannerBGColor {
    if (!_safeBannerBGColor) {
        _safeBannerBGColor = CJPAYISLIGHT ? [UIColor cj_e1fbf8ff] : [UIColor cj_17a37eWithAlpha:0.12];
    }
    return _safeBannerBGColor;
}

- (UIColor *)safeBannerTextColor {
    if(!_safeBannerTextColor) {
        _safeBannerTextColor = CJPAYISLIGHT ? [UIColor cj_418f82ff] : [UIColor cj_17a37eff];
    }
    return _safeBannerTextColor;
}

- (UIColor *)navigationLeftButtonTintColor {
    if (!_navigationLeftButtonTintColor) {
        _navigationLeftButtonTintColor = CJPAYISLIGHT ? nil : [UIColor cj_colorWithHexString:@"#F7F7F7" alpha:1];
    }
    return _navigationLeftButtonTintColor;
}

- (UIColor *)navigationBarBackgroundColor {
    if (!_navigationBarBackgroundColor) {
        _navigationBarBackgroundColor = CJPAYISLIGHT ? [UIColor cj_ffffffWithAlpha:1] : [UIColor cj_161823ff];
    }
    return _navigationBarBackgroundColor;
}

- (UIColor *)navigationBarTitleColor {
    if (!_navigationBarTitleColor) {
        _navigationBarTitleColor = CJPAYISLIGHT ? [UIColor cj_colorWithHexString:@"#222222" alpha:1] : [UIColor cj_ffffffWithAlpha:1];
    }
    return _navigationBarTitleColor;
}

- (UIColor *)addBankButtonBackgroundColor {
    if (!_addBankButtonBackgroundColor) {
        _addBankButtonBackgroundColor = CJPAYISLIGHT ? [UIColor whiteColor] : [UIColor cj_ffffffWithAlpha:0.15];
    }
    return _addBankButtonBackgroundColor;
}

- (UIColor *)addBankBigButtonBackgroundColor {
    if (!_addBankBigButtonBackgroundColor) {
        _addBankBigButtonBackgroundColor = CJPAYISLIGHT ? [UIColor whiteColor] : [UIColor cj_ffffffWithAlpha:0.03];
    }
    return _addBankBigButtonBackgroundColor;
}

- (UIColor *)syncUnionCellDivideBackgroundColor {
    if (!_syncUnionCellDivideBackgroundColor) {
        _syncUnionCellDivideBackgroundColor = CJPAYISLIGHT ? [UIColor cj_colorWithHexString:@"#000000" alpha:0.28] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _syncUnionCellDivideBackgroundColor;
}

- (CGFloat)syncUnionCellBorderWidth {
    if (!_syncUnionCellBorderWidth) {
        _syncUnionCellBorderWidth = CJPAYISLIGHT ? 0.5 : 0;
    }
    return _syncUnionCellBorderWidth;
}

- (UIColor *)addBankButtonTitleColor {
    if (!_addBankButtonTitleColor) {
        _addBankButtonTitleColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _addBankButtonTitleColor;
}

- (UIColor *)addBankButtonBorderColor {
    if (!_addBankButtonBorderColor) {
        _addBankButtonBorderColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.12] : [UIColor cj_ffffffWithAlpha:0.15];
    }
    return _addBankButtonBorderColor;
}

- (UIColor *)addBankButtonIconBackgroundColor {
    if (!_addBankButtonIconBackgroundColor) {
        _addBankButtonIconBackgroundColor = CJPAYISLIGHT ? [UIColor cj_ff4e33ff] : [UIColor cj_ffffffWithAlpha:0.15];
    }
    return _addBankButtonIconBackgroundColor;
}

- (UIColor *)addBankButtonNormalTitleColor {
    if (!_addBankButtonNormalTitleColor) {
        _addBankButtonNormalTitleColor = [UIColor cj_ffffffWithAlpha:CJPAYISLIGHT ? 1 : 0.9];
    }
    return _addBankButtonNormalTitleColor;
}

- (NSString *)addBankButtonNormalArrowImageName {
    if (!_addBankButtonNormalArrowImageName) {
        _addBankButtonNormalArrowImageName = CJPAYISLIGHT ? @"cj_bank_card_list_arrow_light_icon" : @"cj_bank_card_list_arrow_dark_icon";
    }
    return _addBankButtonNormalArrowImageName;
}

- (UIColor *)faqTextColor {
    if (!_faqTextColor) {
        _faqTextColor = CJPAYISLIGHT ? [UIColor cj_douyinBlueColor] : [UIColor cj_colorWithHexString:@"#FACE15"];
    }
    return _faqTextColor;
}

- (UIColor *)bankActivityMainTitleColor {
    if (!_bankActivityMainTitleColor) {
        _bankActivityMainTitleColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _bankActivityMainTitleColor;
}

- (UIColor *)bankActivitySubTitleColor {
    if (!_bankActivitySubTitleColor) {
        _bankActivitySubTitleColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_ffffffWithAlpha:0.5];
    }
    return _bankActivitySubTitleColor;
}

- (UIColor *)bankActivityBorderColor {
    if (!_bankActivityBorderColor) {
        _bankActivityBorderColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.12] : [UIColor cj_ffffffWithAlpha:0.03];
    }
    return _bankActivityBorderColor;
}

- (UIColor *)dyNumberBorderColor {
    if (!_dyNumberBorderColor) {
        _dyNumberBorderColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.12] : [UIColor cj_ffffffWithAlpha:0.03];
    }
    return _dyNumberBorderColor;
}

- (UIColor *)unbindCardTextColor {
    if (!_unbindCardTextColor) {
        _unbindCardTextColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"FE2C55" : @"#FACE15"];
    }
    return _unbindCardTextColor;
}

- (UIColor *)keyBoardBgColor {
    if (!_keyBoardBgColor) {
        _keyBoardBgColor = CJPAYISLIGHT ? [UIColor cj_f8f8f8ff] : [UIColor cj_161823ff];
    }
    return _keyBoardBgColor;
}

- (UIColor *)rechargeCardTitleTextColor {
    if (!_rechargeCardTitleTextColor) {
        _rechargeCardTitleTextColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#222222" : @"#8a8b91" alpha:1];
    }
    return _rechargeCardTitleTextColor;
}

- (UIColor *)rechargeTitleTextColor {
    if (!_rechargeTitleTextColor) {
        _rechargeTitleTextColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#999999" : @"#8a8b91" alpha:1];
    }
    return _rechargeTitleTextColor;
}

- (UIColor *)rechargeContentTextColor {
    if (!_rechargeContentTextColor) {
        _rechargeContentTextColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#222222" : @"#e9e9ea" alpha:1];
    }
    return _rechargeContentTextColor;
}

- (UIColor *)rechargeResultTextColor {
    if (!_rechargeResultTextColor) {
        _rechargeResultTextColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#2c2f36" : @"#e9e9ea" alpha:1];
    }
    return _rechargeResultTextColor;
}

- (UIColor *)rechargeLinkTextColor {
    if (!_rechargeLinkTextColor) {
        _rechargeLinkTextColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _rechargeLinkTextColor;
}

- (UIColor *)rechargeBackgroundColor {
    if (!_rechargeBackgroundColor) {
        _rechargeBackgroundColor = CJPAYISLIGHT ? [UIColor cj_f8f8f8ff] : [UIColor clearColor];
    }
    return _rechargeBackgroundColor;
}

- (UIColor *)rechargeMainViewBackgroundColor {
    if (!_rechargeMainViewBackgroundColor) {
        _rechargeMainViewBackgroundColor = CJPAYISLIGHT ? [UIColor whiteColor] : [UIColor cj_ffffffWithAlpha:0.02];
    }
    return _rechargeMainViewBackgroundColor;
}

- (UIColor *)rechargeResultStateTextColor {
    if (!_rechargeResultStateTextColor) {
        _rechargeResultStateTextColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.75] : [UIColor cj_ffffffWithAlpha:0.75];
    }
    return _rechargeResultStateTextColor;
}

- (UIColor *)rechargeResultStateTextColorV2 {
    if (!_rechargeResultStateTextColorV2) {
        _rechargeResultStateTextColorV2 = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:1] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _rechargeResultStateTextColorV2;
}

- (UIColor *)rechargeCompletionButtonBgColor {
    if (!_rechargeCompletionButtonBgColor) {
        _rechargeCompletionButtonBgColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.05] : [UIColor cj_ffffffWithAlpha:0.15];
    }
    return _rechargeCompletionButtonBgColor;
}

- (NSString *)rechargeSuccessIconName {
    if (!_rechargeSuccessIconName) {
        _rechargeSuccessIconName = CJPAYISLIGHT ? @"cj_recharge_light_success_icon" : @"cj_recharge_dark_success_icon";
    }
    return _rechargeSuccessIconName;
}

- (NSString *)rechargeProcessIconName {
    if (!_rechargeProcessIconName) {
        _rechargeProcessIconName = CJPAYISLIGHT ? @"cj_recharge_light_process_icon" : @"cj_recharge_dark_process_icon";
    }
    return _rechargeProcessIconName;
}

- (UIColor *)rechargeCopyButtonColor {
    if (!_rechargeCopyButtonColor) {
        _rechargeCopyButtonColor = CJPAYISLIGHT ? [UIColor cj_fe2c55ff] : [UIColor cj_face15ff];
    }
    return _rechargeCopyButtonColor;
}

- (NSString *)resultSuccessIconName {
    if (!_resultSuccessIconName) {
        _resultSuccessIconName = CJPAYISLIGHT ? @"cj_result_success_icon" : @"cj_result_success_icon";
    }
    return _resultSuccessIconName;
}

- (NSString *)resultProcessIconName {
    if (!_resultProcessIconName) {
        _resultProcessIconName = CJPAYISLIGHT ? @"cj_result_processing_icon" : @"cj_result_processing_dark_icon";
    }
    return _resultProcessIconName;
}

- (NSString *)resultFailIconName {
    if (!_resultFailIconName) {
        _resultFailIconName = CJPAYISLIGHT ? @"cj_result_fail_icon" : @"cj_result_failure_dark_icon";
    }
    return _resultFailIconName;
}

- (UIColor *)withdrawBlockedProcessBackgroundColor {
    if (!_withdrawBlockedProcessBackgroundColor) {
        _withdrawBlockedProcessBackgroundColor = CJPAYISLIGHT ? [UIColor cj_f85959ff] : [UIColor cj_colorWithHexString:@"#fe2c55" alpha:1];
    }
    return _withdrawBlockedProcessBackgroundColor;
}

- (UIColor *)withdrawDoneProcessBackgroundColor {
    if (!_withdrawDoneProcessBackgroundColor) {
        _withdrawDoneProcessBackgroundColor = CJPAYISLIGHT ? [UIColor cj_douyinBlueColor] : [UIColor cj_colorWithHexString:@"#face15" alpha:1];
    }
    return _withdrawDoneProcessBackgroundColor;
}

- (UIColor *)withdrawUpcomingProcessBackgroundColor {
    if (!_withdrawUpcomingProcessBackgroundColor) {
        _withdrawUpcomingProcessBackgroundColor = CJPAYISLIGHT ? [UIColor cj_e8e8e8ff] : [UIColor cj_colorWithHexString:@"#383a43" alpha:1];
    }
    return _withdrawUpcomingProcessBackgroundColor;
}

- (UIColor *)withdrawArrivingViewBottomLineColor {
    if (!_withdrawArrivingViewBottomLineColor) {
        _withdrawArrivingViewBottomLineColor = CJPAYISLIGHT ? [UIColor cj_f4f5f6ff] : [UIColor cj_161823ff];
    }
    return _withdrawArrivingViewBottomLineColor;
}

- (UIColor *)withdrawBackgroundColor {
    if (!_withdrawBackgroundColor) {
        _withdrawBackgroundColor = CJPAYISLIGHT ? [UIColor whiteColor] : [UIColor cj_161823ff];
    }
    return _withdrawBackgroundColor;
}

- (UIColor *)withdrawBackgroundColorV2 {
    if (!_withdrawBackgroundColorV2) {
        _withdrawBackgroundColorV2 = CJPAYISLIGHT ? [UIColor cj_f8f8f8ff] : [UIColor cj_161823ff];
    }
    return _withdrawBackgroundColorV2;
}

- (UIColor *)withdrawTitleTextColor {
    if (!_withdrawTitleTextColor) {
        _withdrawTitleTextColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _withdrawTitleTextColor;
}

- (UIColor *)withdrawAmountTextColor {
    if (!_withdrawAmountTextColor) {
        _withdrawAmountTextColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _withdrawAmountTextColor;
}

- (UIColor *)withdrawSubTitleTextColor {
    if (!_withdrawSubTitleTextColor) {
        _withdrawSubTitleTextColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_ffffffWithAlpha:0.5];
    }
    return _withdrawSubTitleTextColor;
}

- (UIColor *)withdrawSubTitleTextColorV2 {
    if (!_withdrawSubTitleTextColorV2) {
        _withdrawSubTitleTextColorV2 = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_ffffffWithAlpha:0.75];
    }
    return _withdrawSubTitleTextColorV2;
}

- (UIColor *)withdrawUpcomingTextColor {
    if (!_withdrawUpcomingTextColor) {
        _withdrawUpcomingTextColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.34] : [UIColor cj_ffffffWithAlpha:0.34];
    }
    return _withdrawUpcomingTextColor;
}

- (UIColor *)withdrawHeaderViewBottomLineColor {
    if (!_withdrawHeaderViewBottomLineColor) {
        _withdrawHeaderViewBottomLineColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.12] : [UIColor cj_ffffffWithAlpha:0.08];
    }
    return _withdrawHeaderViewBottomLineColor;
}

- (UIColor *)withdrawProcessViewTopLineColor {
    if (!_withdrawProcessViewTopLineColor) {
        _withdrawProcessViewTopLineColor = CJPAYISLIGHT ? [UIColor cj_f4f5f6ff] : [UIColor cj_colorWithHexString:@"#393b44" alpha:1];
    }
    return _withdrawProcessViewTopLineColor;
}

- (UIColor *)withdrawResultBottomTitleTextColor {
    if (!_withdrawResultBottomTitleTextColor) {
        _withdrawResultBottomTitleTextColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_ffffffWithAlpha:0.5];
    }
    return _withdrawResultBottomTitleTextColor;
}

- (UIColor *)withdrawResultBottomDetailTextColor {
    if (!_withdrawResultBottomDetailTextColor) {
        _withdrawResultBottomDetailTextColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _withdrawResultBottomDetailTextColor;
}

- (UIColor *)withdrawSegmentBackgroundColor {
    if (!_withdrawSegmentBackgroundColor) {
        _withdrawSegmentBackgroundColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.12] : [UIColor cj_ffffffWithAlpha:0.12];
    }
    return _withdrawSegmentBackgroundColor;
}

- (NSString *)withdrawResultIconImageTwoName {
    if (!_withdrawResultIconImageTwoName) {
        _withdrawResultIconImageTwoName = CJPAYISLIGHT ? @"cj_withdraw_two_icon" : @"cj_withdraw_two_dark_icon";
    }
    return _withdrawResultIconImageTwoName;
}

- (NSString *)withdrawResultIconImageThreeName {
    if (!_withdrawResultIconImageThreeName) {
        _withdrawResultIconImageThreeName = CJPAYISLIGHT ? @"cj_withdraw_three_icon" : @"cj_withdraw_three_dark_icon";
    }
    return _withdrawResultIconImageThreeName;
}

- (UIColor *)withdrawResultHeaderTitleTextColor {
    if (!_withdrawResultHeaderTitleTextColor) {
        _withdrawResultHeaderTitleTextColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.75] : [UIColor cj_ffffffWithAlpha:0.75];
    }
    return _withdrawResultHeaderTitleTextColor;
}

- (UIColor *)withDrawAllbtnTextColor {
    if (!_withDrawAllbtnTextColor) {
        _withDrawAllbtnTextColor = CJPAYISLIGHT ? [UIColor cj_fe2c55ff] : [UIColor cj_face15ff];
    }
    return _withDrawAllbtnTextColor;
}

- (UIColor *)withdrawServiceTextColor {
    if (!_withdrawServiceTextColor) {
        _withdrawServiceTextColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.34] : [UIColor cj_ffffffWithAlpha:0.34];
    }
    return _withdrawServiceTextColor;
}

- (NSString *)withdrawArrowImageName {
    if (!_withdrawArrowImageName) {
        _withdrawArrowImageName = CJPAYISLIGHT ? @"cj_withdraw_arrow_light_icon" : @"cj_withdraw_arrow_dark_icon";
    }
    return _withdrawArrowImageName;
}

- (UIColor *)withdrawLimitTextColor {
    if (!_withdrawLimitTextColor) {
        _withdrawLimitTextColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _withdrawLimitTextColor;
}

- (UIColor *)withdrawLimitTextColorV2 {
    if (!_withdrawLimitTextColorV2) {
        _withdrawLimitTextColorV2 = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_ffffffWithAlpha:0.5];
    }
    return _withdrawLimitTextColorV2;
}

- (UIColor *)withDrawNoticeViewHornTintColor {
    if (!_withDrawNoticeViewHornTintColor) {
        _withDrawNoticeViewHornTintColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.6]: [UIColor cj_ffffffWithAlpha:0.5];
    }
    return _withDrawNoticeViewHornTintColor;
}

- (UIColor *)withDrawNoticeViewBackgroundColor {
    if (!_withDrawNoticeViewBackgroundColor) {
        _withDrawNoticeViewBackgroundColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.03]: [UIColor cj_ffffffWithAlpha:0.06];
    }
    return _withDrawNoticeViewBackgroundColor;
}

- (UIColor *)withDrawNoticeViewTextColor {
    if (!_withDrawNoticeViewTextColor) {
        _withDrawNoticeViewTextColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _withDrawNoticeViewTextColor;
}


- (UIColor *)payRechargeViewbackgroundColor {
    if (!_payRechargeViewbackgroundColor) {
        _payRechargeViewbackgroundColor = [UIColor cj_ffffffWithAlpha:CJPAYISLIGHT ? 1 : 0.03];
    }
    return _payRechargeViewbackgroundColor;
}

- (UIColor *)payRechargeViewTextColor {
    if (!_payRechargeViewTextColor) {
        _payRechargeViewTextColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _payRechargeViewTextColor;
}

- (UIColor *)payRechargeViewSubTextColor {
    if (!_payRechargeViewSubTextColor) {
        _payRechargeViewSubTextColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#999999" : @"#8a8b91" alpha:1];
    }
    return _payRechargeViewSubTextColor;
}

- (UIColor *)payRechargeMainViewTopLineColor {
    if (!_payRechargeMainViewTopLineColor) {
        _payRechargeMainViewTopLineColor = CJPAYISLIGHT ? [UIColor cj_ffffffWithAlpha:1] : [UIColor cj_colorWithHexString:@"#393b44" alpha:1];
    }
    return _payRechargeMainViewTopLineColor;
}

- (UIColor *)payRechargeMainViewShadowsColor {
    if (!_payRechargeMainViewShadowsColor) {
        _payRechargeMainViewShadowsColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#e8e8e8" : @"#393b44" alpha:1];
    }
    return _payRechargeMainViewShadowsColor;
}

- (UIColor *)payRechargeMainViewShadowsColorV2 {
    if (!_payRechargeMainViewShadowsColorV2) {
        _payRechargeMainViewShadowsColorV2 = CJPAYISLIGHT ? [UIColor cj_e8e8e8ff] : [UIColor cj_ffffffWithAlpha:0.12];;
    }
    return _payRechargeMainViewShadowsColorV2;
}

- (UIColor *)withDrawRecordbtnTextColor {
    if (!_withDrawRecordbtnTextColor) {
        _withDrawRecordbtnTextColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#2a90d7" : @"#face15" alpha:1];
    }
    return _withDrawRecordbtnTextColor;
}

- (UIColor *)drawBalanceSrcollViewBackgroundColor {
    if (!_drawBalanceSrcollViewBackgroundColor) {
        _drawBalanceSrcollViewBackgroundColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#fff7ea" : @"#393b43" alpha:1];
    }
    return _drawBalanceSrcollViewBackgroundColor;
}

- (UIColor *)drawBalanceSrcollViewTextColor {
    if (!_drawBalanceSrcollViewTextColor) {
        _drawBalanceSrcollViewTextColor = [UIColor cj_colorWithHexString:CJPAYISLIGHT ? @"#f39926" : @"#face15" alpha:1];
    }
    return _drawBalanceSrcollViewTextColor;
}

- (UIColor *)promotionTagColor {
    if (!_promotionTagColor) {
        _promotionTagColor = CJPAYISLIGHT ? [UIColor cj_fe2c55ff] : [UIColor cj_face15ff];
    }
    return _promotionTagColor;
}

- (UIColor *)quickBindCardTitleTextColor {
    if (!_quickBindCardTitleTextColor) {
        _quickBindCardTitleTextColor = CJPAYISLIGHT ? [UIColor cj_colorWithHexString:@"#161823"] : [UIColor cj_ffffffWithAlpha:0.9];
    }
    return _quickBindCardTitleTextColor;
}

- (UIColor *)quickBindCardDescTextColor {
    if (!_quickBindCardDescTextColor) {
        _quickBindCardDescTextColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.5] : [UIColor cj_ffffffWithAlpha:0.5];
    }
    return _quickBindCardDescTextColor;
}

- (UIColor *)quickBindCardBorderColor {
    if (!_quickBindCardBorderColor) {
        _quickBindCardBorderColor = CJPAYISLIGHT ? [UIColor cj_e8e8e8ff] : [UIColor cj_ffffffWithAlpha:0.08];
    }
    return _quickBindCardBorderColor;
}

- (NSString *)quickBindCardRightArrowImgName {
    if (!_quickBindCardRightArrowImgName) {
        _quickBindCardRightArrowImgName = CJPAYISLIGHT ? @"cj_quick_bindcard_arrow_light_icon" : @"cj_quick_bindcard_arrow_dark_icon";
    }
    return _quickBindCardRightArrowImgName;
}

- (NSString *)navigationBarMoreImageName {
    if (!_navigationBarMoreImageName) {
        _navigationBarMoreImageName = CJPAYISLIGHT ? @"cj_pm_more_icon" : @"cj_pm_more_dark_icon";
    }
    return _navigationBarMoreImageName;
}

- (UIImage *)navigationBarBackButtonImage {
    if (!_navigationBarBackButtonImage) {
        _navigationBarBackButtonImage = [UIImage cj_imageWithName:CJPAYISLIGHT ? @"cj_navback_icon" : @"cj_navback_dark_icon"];
    }
    return _navigationBarBackButtonImage;
}

- (NSString *)addBankButtonIconImageName {
    if (!_addBankButtonIconImageName) {
        _addBankButtonIconImageName = CJPAYISLIGHT ? @"cj_pm_add_card_icon" : @"cj_pm_add_card_dark_icon";
    }
    return _addBankButtonIconImageName;
}

- (NSString *)unbindCardArrowImageName {
    if (!_unbindCardArrowImageName) {
        _unbindCardArrowImageName = CJPAYISLIGHT ? @"cj_arrow_unbind_icon" : @"cj_arrow_unbind_dark_icon";
    }
    return _unbindCardArrowImageName;
}

- (NSString *)deleteImageName {
    if (!_deleteImageName) {
        _deleteImageName = CJPAYISLIGHT ? @"cj_keyboard_delete_icon" : @"cj_keyboard_delete_dark_icon";
    }
    return _deleteImageName;
}

- (UIColor *)fontColor {
    if (!_fontColor) {
        _fontColor = CJPAYISLIGHT ? UIColor.cj_222222ff : [UIColor cj_colorWithHexString:@"#e9e9ea"];
    }
    return _fontColor;
}

- (UIColor *)borderColor {
    if (!_borderColor) {
        _borderColor = CJPAYISLIGHT ? [UIColor cj_colorWithHexString:@"f8f8f8"] : [UIColor cj_colorWithHexString:@"#8F8E8F" alpha:0.3];
    }
    return _borderColor;
}

- (UIColor *)gridBlankBackgroundColor {
    if (!_gridBlankBackgroundColor) {
        _gridBlankBackgroundColor = CJPAYISLIGHT ? [UIColor cj_colorWithHexString:@"f8f8f8"] : [UIColor cj_161823ff];
    }
    return _gridBlankBackgroundColor;
}

- (UIColor *)gridNormalColor {
    if (!_gridNormalColor) {
        _gridNormalColor = CJPAYISLIGHT ? UIColor.whiteColor : [UIColor cj_colorWithHexString:@"8F8E8F" alpha:0.3];
    }
    return _gridNormalColor;
}

- (UIColor *)gridHighlightColor {
    if (!_gridHighlightColor) {
        _gridHighlightColor = CJPAYISLIGHT ? UIColor.cj_e8e8e8ff : [UIColor cj_colorWithHexString:@"5B5B5B" alpha:0.4];
    }
    return _gridHighlightColor;
}

- (UIColor *)deleteNormalColor {
    if (!_deleteNormalColor) {
        _deleteNormalColor = CJPAYISLIGHT ? [UIColor whiteColor] : [UIColor cj_colorWithHexString:@"8F8E8F" alpha:0.3];
    }
    return _deleteNormalColor;
}

- (UIColor *)deleteHighlightColor {
    if (!_deleteHighlightColor) {
        _deleteHighlightColor = CJPAYISLIGHT ? UIColor.cj_e8e8e8ff : [UIColor cj_colorWithHexString:@"5B5B5B" alpha:0.4];
    }
    return _deleteHighlightColor;
}

- (UIColor *)amountKeyboardTitleColor {
    if (!_amountKeyboardTitleColor) {
        _amountKeyboardTitleColor = CJPAYISLIGHT ? [UIColor cj_161823ff] : [UIColor cj_ffffffWithAlpha:0.9] ;
    }
    return _amountKeyboardTitleColor;
}

- (NSString *)amountKeyboardDeleteIcon {
    if (!_amountKeyboardDeleteIcon) {
        _amountKeyboardDeleteIcon = CJPAYISLIGHT ? @"cj_im_keyboard_delete" : @"cj_im_keyboard_dark_delete";
    }
    return _amountKeyboardDeleteIcon;
}

- (UIColor *)amountKeyboardButtonColor {
    if (!_amountKeyboardButtonColor) {
        _amountKeyboardButtonColor = CJPAYISLIGHT ? [UIColor cj_ffffffWithAlpha:1] : [UIColor cj_colorWithHexString:@"383C46"] ;
    }
    return _amountKeyboardButtonColor;
}

- (UIColor *)amountKeyboardButtonSelectColor {
    if (!_amountKeyboardButtonSelectColor) {
        _amountKeyboardButtonSelectColor = CJPAYISLIGHT ? [UIColor cj_161823WithAlpha:0.1] : [UIColor cj_colorWithHexString:@"4E5059"];
    }
    return _amountKeyboardButtonSelectColor;
}

- (UIColor *)amountKeyboardBgColor {
    if (!_amountKeyboardBgColor) {
        _amountKeyboardBgColor = CJPAYISLIGHT ? [UIColor cj_colorWithHexString:@"F1F1F2"] : [UIColor cj_colorWithHexString:@"222631"];
    }
    return _amountKeyboardBgColor;
}

- (NSString *)amountKeyboardTopBgColor {
    if (!_amountKeyboardTopBgColor) {
        _amountKeyboardTopBgColor = CJPAYISLIGHT ? @"light" : @"dark";
    }
    return _amountKeyboardTopBgColor;
}

@end
