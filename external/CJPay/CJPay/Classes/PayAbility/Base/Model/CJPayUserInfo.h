//
//  CJPayUserInfo.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/20.
//

#import <Foundation/Foundation.h>
#import "CJPayUserInfoPassModel.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayPwdCheckWay) {
    CJPayPwdCheckWayPWD,
    CJPayPwdCheckWayFingerPrint,
    CJPayPwdCheckWayFaceDec,
};

@protocol CJPayUserInfoPassModel;
@interface CJPayUserInfo : JSONModel

@property (nonatomic, copy) NSString *authStatus; //实名认证状态 0:未实名  1:已实名   2：已撤销
@property (nonatomic, copy) NSString *authUrl; //  实名url
@property (nonatomic, copy) NSString *lynxAuthUrl; //  lynx开户schema
@property (nonatomic, copy) NSString *certificateNum; //认证证件号
@property (nonatomic, copy) NSString *certificateType;  //证件类型
@property (nonatomic, copy) NSString *mName;
@property (nonatomic, copy) NSString *mid;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *uidType;
@property (nonatomic, copy) NSString *findPwdURL; // 找回密码url
@property (nonatomic, copy) NSString *pwdStatus; // 0 没有支付密码   1有支付密码（密码正常）   2有密码（密码锁定）
@property (nonatomic, copy) NSString *addPwdUrl;
@property (nonatomic, assign) NSInteger payIdState; // 用户状态 1新用户 非1老用户 // 各端同步
@property (nonatomic, assign) BOOL isNewUser; // 是否为新用户
@property (nonatomic, copy) NSString *bindUrl; // 如果为空会返回authurl
@property (nonatomic, copy) NSString *decLiveUrl; // 活体url
@property (nonatomic, copy) NSString *pwdCheckWay; //0: 支付(数字)密码验证；1：指纹密码验证，2：人脸密码验证  //以后可能还会有别的密码验证方式或者免密
@property (nonatomic, copy) NSString *accountMobile;
@property (nonatomic, copy) NSString *mobile;  //用户开户手机号掩码
@property (nonatomic, copy) NSString *uidMobileMask; // 宿主端 uid 对应的手机号掩码
@property (nonatomic, strong) CJPayUserInfoPassModel *passModel;
@property (nonatomic, assign) BOOL redirectBind;
@property (nonatomic, copy) NSString *balanceAmount;
@property (nonatomic, assign) BOOL needAuthGuide;
@property (nonatomic, assign) BOOL payAfterUseActive;
@property (nonatomic, assign) BOOL hasSignedCards;
@property (nonatomic, assign) BOOL needCompleteUserInfo; //是否需要完善实名信息
@property (nonatomic, copy) NSString *completeUrl;  //实名信息页面跳转url
@property (nonatomic, copy, nullable) NSString *completeLynxUrl; //实名信息页面lynx url
@property (nonatomic, copy) NSString *completeHintTitle;  //实名信息弹窗文案
@property (nonatomic, copy, nullable) NSString *completeType; //实名信息页面跳转类型 lynx or h5
@property (nonatomic, copy, nullable) NSString *completeRightText; //实名弹窗右button文案
@property (nonatomic, assign) NSInteger completeOrderTimes; //实名弹窗频次
@property (nonatomic, assign, readonly) BOOL isNeedAddPwd;

@property (nonatomic, copy) NSString *chargeWithdrawStyle; // 零钱充提绑卡实验组


//支付账户状态,
//1：全新
//2：pid对应手机号已被别的uid绑定，
//3：pid被当前uid绑定
//4: 状态1的变体(手机号是从passport拿到的)，需要验证短信验证码

- (BOOL)hasValidAuthStatus;

@end

NS_ASSUME_NONNULL_END
