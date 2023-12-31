//
//  CJPayMemCardBinResponse.h
//  Pods
//
//  Created by 尚怀军 on 2020/2/20.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayMemBankInfoModel;
@class CJPayMemAgreementModel;
@protocol CJPayMemAgreementModel;
@class CJPayQuickPayUserAgreement;
@class CJPayErrorButtonInfo;
@interface CJPayMemCardBinResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, strong) CJPayMemBankInfoModel *cardBinInfoModel;
@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *agreements;
@property (nonatomic, copy) NSString *guideMessage;
@property (nonatomic, copy) NSString *protocolCheckBox;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;

- (NSDictionary *)toActivityInfoTracker;

@end

NS_ASSUME_NONNULL_END
