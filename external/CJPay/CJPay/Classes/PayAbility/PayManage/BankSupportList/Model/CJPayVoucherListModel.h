//
//  CJPayVoucherListModel.h
//  Pods
//
//  Created by chenbocheng.moon on 2022/10/16.
//

#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVoucherListModel : JSONModel

@property (nonatomic, copy) NSString *mixVoucherMsg;
@property (nonatomic, copy) NSString *basicVoucherMsg;

@end

NS_ASSUME_NONNULL_END
