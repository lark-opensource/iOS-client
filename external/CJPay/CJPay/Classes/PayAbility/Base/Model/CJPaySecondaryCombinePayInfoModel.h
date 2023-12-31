//
//  CJPaySecondaryCombinePayInfoModel.h
//  Pods
//
//  Created by 高航 on 2022/6/21.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySecondaryCombinePayInfoModel : JSONModel

@property (nonatomic, assign) NSInteger tradeAmount;
@property (nonatomic, assign) NSInteger primaryAmount;
@property (nonatomic, assign) NSInteger secondaryAmount;

@end

NS_ASSUME_NONNULL_END
