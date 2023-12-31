//
//  CJPayModifyMemberElementsResponse.h
//  CJPay
//
//  Created by youerwei on 2022/6/22.
//

#import "CJPayBaseResponse.h"
#import "CJPayErrorButtonInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayModifyMemberElementsResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

NS_ASSUME_NONNULL_END
