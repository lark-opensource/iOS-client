//
//  CJPayCombinePayFund.h
//  Pods
//
//  Created by youerwei on 2021/4/16.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCombinePayFund : JSONModel

@property (nonatomic, copy) NSString *fundTypeDesc;
@property (nonatomic, copy) NSString *fundType;
@property (nonatomic, copy) NSString *fundAmountDesc;
@property (nonatomic, assign) NSInteger fundAmount;

@end

NS_ASSUME_NONNULL_END
