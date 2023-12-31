//
//  CJPayFullResultPageViewController.h
//  CJPaySandBox
//
//  Created by 高航 on 2022/11/29.
//

#import "CJPayFullPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayResultPageModel;
@interface CJPayFullResultPageViewController : CJPayFullPageBaseViewController

@property (nonatomic, copy) void(^closeCompletion)(void);

- (instancetype)initWithCJResultModel:(CJPayResultPageModel *)model trackerParams:(NSDictionary *)params;


@end

NS_ASSUME_NONNULL_END
