//
//  CJPayQueryPayTypeResponse.h
//  Pods
//
//  Created by wangxiaohong on 2021/7/19.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayIntegratedChannelModel;
@interface CJPayQueryPayTypeResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayIntegratedChannelModel *tradeInfo;

@end

NS_ASSUME_NONNULL_END
