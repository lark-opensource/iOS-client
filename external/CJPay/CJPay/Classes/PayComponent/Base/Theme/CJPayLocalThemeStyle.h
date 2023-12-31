//
//  CJPayLocalThemeStyle.h
//  Pods
//
//  Created by 王新华 on 2020/12/4.
//

#import <Foundation/Foundation.h>
#import "CJPayServerThemeStyle.h"

typedef NS_ENUM(NSUInteger, CJPayLocalThemeStyleType) {
    CJPayLocalThemeStyleLight = 0,
    CJPayLocalThemeStyleDark
};

NS_ASSUME_NONNULL_BEGIN

@interface CJPayLocalThemeStyle : NSObject

@property (nonatomic, readonly) UIColor *mainBackgroundColor;

@property (nonatomic, readonly) UIColor *navigationBarBackgroundColor;
@property (nonatomic, readonly) UIColor *navigationBarTitleColor;
// 导航条后退按钮的图片，原先用在Web容器、native卡列表场景，后面Web容器支持<、X两种样式，这个属性只给卡列表
@property (nonatomic, readonly) UIImage *navigationBarBackButtonImage;
@property (nonatomic, readonly, nullable) UIColor *navigationLeftButtonTintColor;

@property (nonatomic, readonly) NSString *navigationBarMoreImageName;
@property (nonatomic, readonly) NSString *unbindCardArrowImageName;

@property (nonatomic, readonly) UIColor *separatorColor;
@property (nonatomic, readonly) UIColor *titleColor;
@property (nonatomic, readonly) UIColor *subtitleColor;
@property (nonatomic, readonly) UIColor *limitTextColor;
@property (nonatomic, readonly) UIColor *textFieldPlaceHolderColor;

@property (nonatomic, readonly) UIColor *addBankButtonIconBackgroundColor;

@property (nonatomic, readonly) UIColor *addBankButtonBackgroundColor;
@property (nonatomic, readonly) UIColor *addBankBigButtonBackgroundColor;
@property (nonatomic, readonly) UIColor *syncUnionCellDivideBackgroundColor;
@property (nonatomic, readonly) CGFloat syncUnionCellBorderWidth;
@property (nonatomic, readonly) UIColor *addBankButtonTitleColor;
@property (nonatomic, readonly) UIColor *addBankButtonBorderColor;
@property (nonatomic, readonly) NSString *addBankButtonIconImageName;
@property (nonatomic, readonly) UIColor *addBankButtonNormalTitleColor;
@property (nonatomic, readonly) NSString *addBankButtonNormalArrowImageName;


@property (nonatomic, readonly) UIColor *bankActivityMainTitleColor;
@property (nonatomic, readonly) UIColor *bankActivitySubTitleColor;
@property (nonatomic, readonly) UIColor *bankActivityBorderColor;
@property (nonatomic, readonly) UIColor *dyNumberBorderColor;

@property (nonatomic, readonly) UIColor *faqTextColor;
@property (nonatomic, readonly) UIColor *unbindCardTextColor;

@property (nonatomic, readonly) UIColor *keyBoardBgColor;

@property (nonatomic, readonly) NSString *inputClearImageStr;

@property (nonatomic, readonly) UIColor *safeBannerBGColor;
@property (nonatomic, readonly) UIColor *safeBannerTextColor;

// 充值相关主题适配
@property (nonatomic, readonly) UIColor *rechargeCardTitleTextColor;
@property (nonatomic, readonly) UIColor *rechargeTitleTextColor;
@property (nonatomic, readonly) UIColor *rechargeContentTextColor;
@property (nonatomic, readonly) UIColor *rechargeResultTextColor;
@property (nonatomic, readonly) UIColor *rechargeLinkTextColor;
@property (nonatomic, readonly) UIColor *rechargeBackgroundColor;
@property (nonatomic, readonly) UIColor *rechargeResultStateTextColor;
@property (nonatomic, readonly) UIColor *rechargeResultStateTextColorV2;
@property (nonatomic, readonly) NSString *rechargeSuccessIconName;
@property (nonatomic, readonly) NSString *rechargeProcessIconName;
@property (nonatomic, readonly) UIColor *rechargeCopyButtonColor;
@property (nonatomic, readonly) UIColor *rechargeCompletionButtonBgColor;

@property (nonatomic, readonly) NSString *resultSuccessIconName;
@property (nonatomic, readonly) NSString *resultProcessIconName;
@property (nonatomic, readonly) NSString *resultFailIconName;

@property (nonatomic, readonly) UIColor *payRechargeViewbackgroundColor;
@property (nonatomic, readonly) UIColor *rechargeMainViewBackgroundColor;
@property (nonatomic, readonly) UIColor *payRechargeViewTextColor;
@property (nonatomic, readonly) UIColor *payRechargeViewSubTextColor;
@property (nonatomic, readonly) UIColor *payRechargeMainViewTopLineColor;
@property (nonatomic, readonly) UIColor *payRechargeMainViewShadowsColor;
@property (nonatomic, readonly) UIColor *payRechargeMainViewShadowsColorV2;

// 提现相关主题适配
@property (nonatomic, readonly) UIColor *withdrawTitleTextColor;
@property (nonatomic, readonly) UIColor *withdrawAmountTextColor;
@property (nonatomic, readonly) UIColor *withdrawSubTitleTextColor;
@property (nonatomic, readonly) UIColor *withdrawSubTitleTextColorV2;
@property (nonatomic, readonly) UIColor *withdrawBlockedProcessBackgroundColor;
@property (nonatomic, readonly) UIColor *withdrawDoneProcessBackgroundColor;
@property (nonatomic, readonly) UIColor *withdrawUpcomingProcessBackgroundColor;
@property (nonatomic, readonly) UIColor *withdrawUpcomingTextColor;
@property (nonatomic, readonly) UIColor *withdrawBackgroundColor;
@property (nonatomic, readonly) UIColor *withdrawBackgroundColorV2;
@property (nonatomic, readonly) UIColor *withdrawResultBottomTitleTextColor;
@property (nonatomic, readonly) UIColor *withdrawResultBottomDetailTextColor;
@property (nonatomic, readonly) NSString *withdrawResultIconImageTwoName;
@property (nonatomic, readonly) NSString *withdrawResultIconImageThreeName;
@property (nonatomic, readonly) UIColor *withdrawResultHeaderTitleTextColor;
@property (nonatomic, readonly) UIColor *withdrawSegmentBackgroundColor;
@property (nonatomic, readonly) UIColor *withDrawAllbtnTextColor;
@property (nonatomic, readonly) UIColor *withDrawNoticeViewBackgroundColor;
@property (nonatomic, readonly) UIColor *withDrawNoticeViewTextColor;
@property (nonatomic, readonly) NSString *withdrawArrowImageName;
@property (nonatomic, readonly) UIColor *withdrawLimitTextColor;
@property (nonatomic, readonly) UIColor *withdrawLimitTextColorV2;
@property (nonatomic, readonly) UIColor *withDrawNoticeViewHornTintColor;

@property (nonatomic, readonly) UIColor *withdrawArrivingViewBottomLineColor;
@property (nonatomic, readonly) UIColor *withdrawHeaderViewBottomLineColor;
@property (nonatomic, readonly) UIColor *withdrawProcessViewTopLineColor;

@property (nonatomic, readonly) UIColor *withDrawRecordbtnTextColor;
@property (nonatomic, readonly) UIColor *withdrawServiceTextColor;

@property (nonatomic, readonly) UIColor *drawBalanceSrcollViewBackgroundColor;
@property (nonatomic, readonly) UIColor *drawBalanceSrcollViewTextColor;
@property (nonatomic, readonly) UIColor *promotionTagColor;

//一键绑卡相关主题适配
@property (nonatomic, readonly) UIColor *quickBindCardTitleTextColor;
@property (nonatomic, readonly) UIColor *quickBindCardDescTextColor;
@property (nonatomic, readonly) UIColor *quickBindCardBorderColor;
@property (nonatomic, readonly) NSString *quickBindCardRightArrowImgName;

// 金额键盘主题适配
@property (nonatomic, readonly) UIColor *amountKeyboardButtonColor;
@property (nonatomic, readonly) UIColor *amountKeyboardBgColor;
@property (nonatomic, readonly) UIColor *amountKeyboardTitleColor;
@property (nonatomic, readonly) NSString *amountKeyboardDeleteIcon;
@property (nonatomic, readonly) NSString *amountKeyboardTopBgColor;
@property (nonatomic, readonly) UIColor *amountKeyboardButtonSelectColor;

//自定义键盘主题适配
@property (nonatomic, readonly) NSString *deleteImageName;
@property (nonatomic, readonly) UIColor *fontColor;
@property (nonatomic, readonly) UIColor *borderColor;
@property (nonatomic, readonly) UIColor *gridBlankBackgroundColor;
@property (nonatomic, readonly) UIColor *gridNormalColor;
@property (nonatomic, readonly) UIColor *gridHighlightColor;
@property (nonatomic, readonly) UIColor *deleteNormalColor;
@property (nonatomic, readonly) UIColor *deleteHighlightColor;

+ (CJPayLocalThemeStyle *)lightThemeStyle;
+ (CJPayLocalThemeStyle *)darkThemeStyle;
+ (CJPayLocalThemeStyle *)defaultThemeStyle;

+ (void)updateStyleBy:(CJPayServerThemeStyle *)serverStyle;

@end

NS_ASSUME_NONNULL_END
