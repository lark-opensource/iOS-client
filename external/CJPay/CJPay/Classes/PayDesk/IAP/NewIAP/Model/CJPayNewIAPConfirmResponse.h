//
//  CJPayNewIAPSK1ConfirmResponse.h
//  Pods
//
//  Created by 尚怀军 on 2022/3/8.
//
#import "CJPayBaseResponse.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayNewIAPConfirmModel;
@interface CJPayNewIAPConfirmResponse : CJPayBaseResponse

@property (nonatomic, assign) BOOL finishTransaction;

- (CJPayNewIAPConfirmModel *)toNewIAPConfirmModel;

@end

NS_ASSUME_NONNULL_END
