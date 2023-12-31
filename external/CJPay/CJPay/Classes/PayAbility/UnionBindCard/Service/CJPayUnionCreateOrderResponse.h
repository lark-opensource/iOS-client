//
//  CJPayUnionCreateOrderResponse.h
//  Pods
//
//  Created by xutianxi on 2021/10/8.
//

#import "CJPayBaseResponse.h"
#import "CJPayUnionPaySignInfo.h"
#import "CJPayErrorButtonInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayUnionCreateOrderResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *memberBizOrderNo;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, strong) CJPayUnionPaySignInfo *unionPaySignInfo;
@property (nonatomic, copy) NSString *unionIconUrl;

@end

NS_ASSUME_NONNULL_END
