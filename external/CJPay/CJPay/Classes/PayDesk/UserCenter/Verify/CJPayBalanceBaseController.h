//
//  CJPayBalanceBaseController.h
//  CJPaySandBox
//
//  Created by ByteDance on 2022/12/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBalanceBaseController : NSObject

@property (nonatomic, assign) BOOL isBindCardAndPay;

- (void)push:(UIViewController *)vc
    animated:(BOOL) animated
       topVC:(UIViewController *)topVC;

@end

NS_ASSUME_NONNULL_END
