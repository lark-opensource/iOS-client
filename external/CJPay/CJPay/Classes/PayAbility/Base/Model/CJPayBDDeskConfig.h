//
//  CJPayBDDeskConfig.h
//  CJPay
//
//  Created by wangxinhua on 2020/9/28.
//

#import <Foundation/Foundation.h>
#import "CJPayDeskTheme.h"
#import "CJPayNoticeInfo.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBDDeskConfig : JSONModel


//按钮文本 和 色值
@property (nonatomic, copy) NSString *confirmBtnDesc;
@property (nonatomic, copy) NSString *themeString;

// 收银台样式 0-半屏 1-全屏 2-弹窗 3-直播半屏 4-IES半屏
@property (nonatomic, assign) NSInteger showStyle;

//用户协议信息
@property (nonatomic, copy) NSString *agreementUrl;
@property (nonatomic, assign) BOOL agreementChoose;
@property (nonatomic, copy) NSString *agreementTitle;

//是否展示支付剩余时间
@property (nonatomic, assign) BOOL whetherShowLeftTime;
//支付剩余时间，单位为秒
@property (nonatomic, assign) NSInteger leftTime;
@property (nonatomic, strong) CJPayNoticeInfo *noticeInfo;

@property (nonatomic, copy) NSString *withdrawArrivalTime;
@property (nonatomic, assign) int homePageAction;

- (CJPayDeskTheme *)theme;

- (BOOL)isFastEnterBindCard;

@end

NS_ASSUME_NONNULL_END
