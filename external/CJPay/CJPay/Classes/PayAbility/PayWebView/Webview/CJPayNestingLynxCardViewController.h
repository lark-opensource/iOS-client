//
//  CJPayNestingLynxCardViewController.h
//  Aweme
//
//  Created by ByteDance on 2023/5/6.
//

#import "CJPayFullPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNestingLynxCardViewController : CJPayFullPageBaseViewController

@property (nonatomic, copy) void(^eventBlock)(BOOL isOpenSuccess, NSDictionary *ext);

- (instancetype)initWithSchema:(NSString *)schema data:(NSDictionary *)data;


@end

NS_ASSUME_NONNULL_END
