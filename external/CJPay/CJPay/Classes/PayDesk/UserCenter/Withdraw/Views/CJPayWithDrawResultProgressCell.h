//
//  CJWithdrawResultProgressCell.h
//  CJPay
//
//  Created by liyu on 2019/10/12.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayWithDrawResultProgressItem;

@interface CJPayWithDrawResultProgressCell : UITableViewCell

+ (NSString *)identifier;
+ (CGFloat)cellHeight;

- (void)updateWithItem:(CJPayWithDrawResultProgressItem *)item;

@end

NS_ASSUME_NONNULL_END
