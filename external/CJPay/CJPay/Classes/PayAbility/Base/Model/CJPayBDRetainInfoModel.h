//
//  CJPayBDRetainInfoModel.h
//  Pods
//
//  Created by 王新华 on 2021/8/10.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayRetainVoucherType) {
    CJPayRetainVoucherTypeV1 = 0,
    CJPayRetainVoucherTypeV2,
    CJPayRetainVoucherTypeV3
};

@protocol CJPayRetainMsgModel;
@class CJPayRetainRecommendInfoModel;

@interface CJPayBDRetainInfoModel : JSONModel

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *retainMsgBonusStr;
@property (nonatomic, copy) NSString *retainMsgText;
@property (nonatomic, copy) NSString *retainType;
@property (nonatomic, assign) BOOL showRetainWindow;
@property (nonatomic, copy) NSString *retainPlan;
@property (nonatomic, copy) NSString *retainButtonText;
@property (nonatomic, copy) NSString *choicePwdCheckWay;    //免密情况下验证方式降级
@property (nonatomic, copy) NSString *choicePwdCheckWayTitle;
@property (nonatomic, assign) BOOL showChoicePwdCheckWay;
@property (nonatomic, copy) NSString *forgetPwdVerfyType;
@property (nonatomic, copy) NSString *style; //区分营销样式
@property (nonatomic, copy) NSArray<CJPayRetainMsgModel> *retainMsgTextList;
@property (nonatomic, copy) NSArray<CJPayRetainMsgModel> *retainMsgBonusList;
@property (nonatomic, assign, readonly) CJPayRetainVoucherType voucherType;
@property (nonatomic, assign) BOOL needVerifyRetain; //加验环节是否需要挽留
@property (nonatomic, copy) NSString *type; //feature_voucher：营销功能挽留
@property (nonatomic, strong) CJPayRetainRecommendInfoModel *recommendInfoModel; //营销功能挽留信息

- (BOOL)isfeatureRetain;

@end

NS_ASSUME_NONNULL_END
