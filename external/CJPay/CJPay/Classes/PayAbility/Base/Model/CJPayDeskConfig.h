//
//  CJPayDeskConfig.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import <Foundation/Foundation.h>
#import "CJPayDeskTheme.h"
#import <JSONModel/JSONModel.h>
#import "CJPayEnumUtil.h"

typedef NS_ENUM(NSInteger, CJPayDeskConfigCallBackType) {
    CJPayDeskConfigCallBackTypeAfterClose = 0,
    CJPayDeskConfigCallBackTypeAfterQuery
};

// 收银台配置信息
@interface CJPayDeskConfig : JSONModel

//按钮文本 和 色值
@property (nonatomic, copy) NSString *confirmBtnDesc;
@property (nonatomic, copy) NSString *themeString;
@property (nonatomic, copy) NSString *complianceBtnChangeTag;

// 收银台样式 0-半屏 1-全屏 2-弹窗 3-直播半屏 4-IES半屏 6-品牌升级+组合支付
@property (nonatomic, assign) NSInteger showStyle;

//用户协议信息
@property (nonatomic, copy) NSString *agreementUrl;
@property (nonatomic, assign) BOOL agreementChoose;
@property (nonatomic, copy) NSString *agreementTitle;

//是否显示倒计时
@property (nonatomic, assign) BOOL whetherShowLeftTime;
//倒计时剩余时间，单位为秒
@property (nonatomic, assign) NSInteger leftTime;

@property (nonatomic, copy) NSString *withdrawArrivalTime;

// 端外支付半屏顶部文案
@property (nonatomic, copy) NSString *headerTitle;
@property (nonatomic, assign) NSInteger queryResultTime;
@property (nonatomic, assign) NSInteger remainTime;
@property (nonatomic, copy) NSString *jhResultPageStyle;
@property (nonatomic, copy) NSString *containerViewLynxUrl; //style为7时，lynx卡片的url
@property (nonatomic, assign) NSInteger renderTimeoutTime; //style为7时，lynx卡片的超时时间，超时会自动降级为style=6样式
@property (nonatomic, copy) NSString *callBackTypeStr;
@property (nonatomic, assign) CJPayDeskConfigCallBackType callBackType;

- (CJPayDeskTheme *)theme;

- (CJPayDeskType)currentDeskType;

@end
