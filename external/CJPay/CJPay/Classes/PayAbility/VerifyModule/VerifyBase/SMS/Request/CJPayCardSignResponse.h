//
//  CJPayCardSignResponse.h
//  CJPay
//
//  Created by wangxiaohong on 2020/3/29.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayUserInfo;
@class CJPayQuickPayCardModel;
@class CJPayErrorButtonInfo;
@class CJPayQuickPayUserAgreement;
@class CJPayCardSignInfoModel;
@protocol CJPayUserInfo;
@protocol CJPayQuickPayCardModel;
@protocol CJPayErrorButtonInfo;
@protocol CJPayQuickPayUserAgreement;
@protocol CJPayCardSignInfoModel;
@interface CJPayCardSignResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayUserInfo *userInfo; // 只用到uid和mobile
@property (nonatomic, strong) CJPayQuickPayCardModel *card;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, copy) NSArray<CJPayQuickPayUserAgreement> *agreements;
@property (nonatomic, strong) CJPayCardSignInfoModel *cardSignInfo;

- (NSArray<CJPayQuickPayUserAgreement *> *)getQuickAgreements;

@end

NS_ASSUME_NONNULL_END
