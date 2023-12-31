//
//  CJPayDySignPayDetailViewController.h
//  CJPaySandBox
//
//  Created by ByteDance on 2023/6/28.
//

#import "CJPayFullPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;

@interface CJPayDySignPayDetailViewController : CJPayFullPageBaseViewController

@property (nonatomic, copy) void(^clickBackBlock)(void);

- (instancetype)initWithResponse:(CJPayBDCreateOrderResponse *)response allParamsDict:(NSDictionary *)allParamsDict;

@end

NS_ASSUME_NONNULL_END
