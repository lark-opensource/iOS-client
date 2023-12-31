//
//  CJWithdrawResultProgressView.h
//  CJPay
//
//  Created by liyu on 2019/10/11.
//

#import <UIKit/UIKit.h>

@class CJPayWithDrawResultProgressItem;

NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawResultProgressView : UIView

@property (nonatomic, copy) NSArray <CJPayWithDrawResultProgressItem *> *items;

@end

NS_ASSUME_NONNULL_END
