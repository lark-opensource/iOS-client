//
//  CJPayPrimaryCombinePayInfoModel.h
//  Pods
//
//  Created by 高航 on 2022/6/21.
//

#import <JSONModel/JSONModel.h>

#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPrimaryCombinePayInfoModel : JSONModel

@property (nonatomic, assign) NSInteger secondaryPayTypeIndex;
@property (nonatomic, assign) NSInteger primaryAmount;
@property (nonatomic, assign) NSInteger secondaryAmount;
@property (nonatomic, copy) NSString *primaryAmountString;
@property (nonatomic, copy) NSString *secondaryAmountString;
@property (nonatomic, copy) NSString *secondaryPayTypeStr;
@property (nonatomic, assign, readonly) CJPayChannelType channelType;

@end

NS_ASSUME_NONNULL_END
