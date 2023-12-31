//
//  CJPayMemProtocolListResponse.h
//  Pods
//
//  Created by xiuyuanLee on 2020/10/13.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayQuickPayUserAgreement;
@class CJPayMemAgreementModel;
@protocol CJPayMemAgreementModel;
@interface CJPayMemProtocolListResponse : CJPayBaseResponse

@property (nonatomic, copy) NSArray<CJPayMemAgreementModel> *agreements;
@property (nonatomic, copy) NSString *guideMessage;
@property (nonatomic, copy) NSString *protocolCheckBox;
@property (nonatomic, copy) NSDictionary *protocolGroupNames;

@end

NS_ASSUME_NONNULL_END
