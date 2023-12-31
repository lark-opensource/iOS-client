//
//  CJPayHintInfo.h
//  Pods
//
//  Created by 王新华 on 2021/6/7.
//

#import <JSONModel/JSONModel.h>
#import "CJPayBDRetainInfoModel.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayRetainMsgModel.h"

typedef NS_ENUM(NSUInteger, CJPayHintInfoStyle) {
    CJPayHintInfoStyleNewHalf,
    CJPayHintInfoStyleOldHalf,
    CJPayHintInfoStyleWindow,
    CJPayHintInfoStyleVoucherHalf,
    CJPayHintInfoStyleVoucherHalfV2,
    CJPayHintInfoStyleVoucherHalfV3
};

NS_ASSUME_NONNULL_BEGIN

@class CJPaySubPayTypeInfoModel;
@class CJPayMerchantInfo;
@protocol CJPaySubPayTypeInfoModel;
@interface CJPayHintInfo : JSONModel

@property (nonatomic, copy) NSString *iconUrl;
@property (nonatomic, copy) NSString *msg;

@property (nonatomic, copy) NSString *statusMsg;
@property (nonatomic, copy) NSString *failType;
@property (nonatomic, copy) NSString *subStatusMsg;
@property (nonatomic, copy) NSArray<NSString *> *voucherBankIcons;
@property (nonatomic, strong) CJPaySubPayTypeInfoModel *recPayType;
@property (nonatomic, copy) NSString *buttonText;
@property (nonatomic, copy) NSString *subButtonText;
@property (nonatomic, strong) CJPayBDRetainInfoModel *retainInfo;
@property (nonatomic, strong) NSString *styleStr;
@property (nonatomic, assign, readonly, getter=style) CJPayHintInfoStyle style;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, copy) NSString *topRightDescText;
@property (nonatomic, assign) NSInteger tradeAmount;
@property (nonatomic, copy) NSString *failPayTypeMsg;
@property (nonatomic, strong) CJPayMerchantInfo *merchantInfo;
@property (nonatomic, copy) NSString *titleMsg;
@property (nonatomic, copy) NSString *againReasonType;

@end

NS_ASSUME_NONNULL_END
