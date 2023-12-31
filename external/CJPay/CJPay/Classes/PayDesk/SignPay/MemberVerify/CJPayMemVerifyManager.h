//
//  CJPayMemVerifyManager.h
//  CJPay
//
//  Created by wangxiaohong on 2022/9/19.
//

#import <Foundation/Foundation.h>
#import "CJPayVerifyManagerHeader.h"
#import "CJPayVerifyItem.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayBaseVerifyManagerQueen.h"
#import "CJPayMemVerifyResultModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMemVerifyManager : NSObject<CJPayTrackerProtocol>

- (void)beginMemVerifyWithType:(CJPayVerifyType)type params:(NSDictionary *)params fromVC:(UIViewController *)fromVC completion:(void(^)(CJPayMemVerifyResultModel *resultModel))completedBlock;

@end

NS_ASSUME_NONNULL_END
