//
//  CJPayBizDYPayPluginV2.h
//  aweme_transferpay_opt
//
//  Created by shanghuaijun on 2023/6/17.
//

#import <Foundation/Foundation.h>
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDOrderResultResponse;
@class CJPayBizDYPayModel;

@protocol CJPayBizDYPayPluginV2 <NSObject>

- (void)dyPayWithModel:(CJPayBizDYPayModel *)model
            completion:(void (^)(CJPayOrderStatus orderStatus, CJPayBDOrderResultResponse * _Nonnull))completion;

@end

NS_ASSUME_NONNULL_END
