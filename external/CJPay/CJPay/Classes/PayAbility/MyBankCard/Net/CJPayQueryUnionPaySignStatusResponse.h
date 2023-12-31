//
//  CJPayQueryUnionPaySignStatusResponse.h
//  CJPay-5b542da5
//
//  Created by chenbocheng on 2022/8/31.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayErrorButtonInfo;

@interface CJPayQueryUnionPaySignStatusResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *signStatus;
@property (nonatomic, assign) BOOL needShowUnionPay;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;
@property (nonatomic, copy) NSString *bindCardDouyinIconUrl;
@property (nonatomic, copy) NSString *bindCardUnionIconUrl;

@end

NS_ASSUME_NONNULL_END
