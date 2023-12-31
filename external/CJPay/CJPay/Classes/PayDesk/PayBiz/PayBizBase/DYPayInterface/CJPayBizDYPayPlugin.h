//
//  CJPayBizDYPayPlugin.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/11/7.
//

#import <Foundation/Foundation.h>

#import "CJPaySDKDefine.h"
#import "CJPayBizDYPayModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayDefaultChannelShowConfig;
@class CJPayBDOrderResultResponse;
@protocol CJPayBizDYPayPlugin <NSObject>

- (void)dyPayWithModel:(CJPayBizDYPayModel *)model completion:(void (^)(CJPayOrderStatus orderStatus, CJPayBDOrderResultResponse * _Nonnull))completion;

@end

NS_ASSUME_NONNULL_END
