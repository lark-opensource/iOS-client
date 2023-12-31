//
//  CJPayMemVerifyItem.h
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import <Foundation/Foundation.h>
#import "CJPayMemVerifyResultModel.h"
#import "CJPayMemVerifyManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayMemVerifyItem : NSObject

- (void)verifyWithParams:(NSDictionary *)params fromVC:(UIViewController *)fromVC completion:(void(^)(CJPayMemVerifyResultModel *resultModel))completedBlock;

@property (nonatomic, weak) CJPayMemVerifyManager *verifyManager;

@end

NS_ASSUME_NONNULL_END
