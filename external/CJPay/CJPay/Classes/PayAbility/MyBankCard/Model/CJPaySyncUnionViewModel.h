//
//  CJPaySyncUnionViewModel.h
//  CJPay-5b542da5
//
//  Created by chenbocheng on 2022/9/1.
//

#import "CJPayBaseListViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySyncUnionViewModel : CJPayBaseListViewModel

@property (nonatomic, copy) void(^didClickBlock)(void);
@property (nonatomic, copy) NSString *bindCardDouyinIconUrl;
@property (nonatomic, copy) NSString *bindCardUnionIconUrl;

@end

NS_ASSUME_NONNULL_END
