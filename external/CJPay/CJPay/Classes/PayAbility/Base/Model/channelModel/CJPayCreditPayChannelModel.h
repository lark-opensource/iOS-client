//
//  CJPayCreditPayChannelModel.h
//  CJPaySandBox_3
//
//  Created by wangxiaohong on 2023/3/9.
//

#import "CJPayChannelModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCreditPayChannelModel : CJPayChannelModel

@property (nonatomic, strong) CJPaySubPayTypeData *payTypeData;
@property (nonatomic, copy) NSString *extParamStr;

@end

NS_ASSUME_NONNULL_END
