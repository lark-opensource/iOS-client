//
//  CJPayUnionBindCardSignResponse.h
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayErrorButtonInfo;
@interface CJPayUnionBindCardSignResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
