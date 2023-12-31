//
//  CJPayCardUpdateModel.h
//  CJPay
//
//  Created by 尚怀军 on 2019/11/3.
//

#import <Foundation/Foundation.h>

#import "CJPayCardSignInfoModel.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayQuickPayCardModel;
@class CJPayQuickPayUserAgreement;
@interface CJPayCardUpdateModel : NSObject

@property (nonatomic, copy) NSArray<CJPayQuickPayUserAgreement *> *agreements;
@property (nonatomic, strong) CJPayQuickPayCardModel *cardModel;
@property (nonatomic, strong) CJPayCardSignInfoModel *cardSignInfo;

@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *merchantId;

@end

NS_ASSUME_NONNULL_END
