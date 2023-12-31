//
//  CJPayCommonProtocolModel.h
//  Pods
//
//  Created by 尚怀军 on 2021/3/5.
//

#import <Foundation/Foundation.h>
#import "CJPayMemAgreementModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPaySelectButtonPattern) {
    //无选择按钮
    CJPaySelectButtonPatternNone = 0,
    //左侧checkbox
    CJPaySelectButtonPatternCheckBox,
    //右侧开关
    CJPaySelectButtonPatternSwitch
};


@interface CJPayCommonProtocolModel : NSObject

@property (nonatomic, copy) NSString *guideDesc;
@property (nonatomic, assign) CJPaySelectButtonPattern selectPattern;
@property (nonatomic, assign) BOOL isSelected;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *groupNameDic;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel *> *agreements;
@property (nonatomic, copy) NSArray<NSDictionary *> *guideBar;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *buttonText;
@property (nonatomic, copy) NSString *protocolCheckBoxStr; // 后台控制是否展示勾选框
@property (nonatomic, copy) NSString *tailText;

// 具体实现参考：CJPayCommonProtocolView -> p_updateProtocolContent
/// 协议字体 默认：[UIFont cj_fontOfSize:12]
@property (nonatomic, strong) UIFont *protocolFont;

/// 协议颜色 默认：[UIColor cj_161823WithAlpha:0.75]
@property (nonatomic, strong) UIColor *protocolColor;

/// 协议文本对齐方式 默认：NSTextAlignmentLeft
@property (nonatomic, assign) NSTextAlignment protocolTextAlignment;

/// 跳转协议颜色 默认：[CJPayThemeStyleManager shared].serverTheme.agreementTextColor
@property (nonatomic, strong) UIColor *protocolJumpColor;
@property (nonatomic, strong) NSNumber *protocolDetailContainerHeight;

/// 协议文案行高（设置时至少大于 10，否则取默认值） 默认：CJ_SIZE_FONT_SAFE(20)
@property (nonatomic, assign) CGFloat protocolLineHeight;

@property (nonatomic, assign) BOOL supportRiskControl; // 是否支持合规控制

@property (nonatomic, assign) BOOL isHorizontalCenterLayout; // 是否使用X轴居中样式

@end

NS_ASSUME_NONNULL_END
