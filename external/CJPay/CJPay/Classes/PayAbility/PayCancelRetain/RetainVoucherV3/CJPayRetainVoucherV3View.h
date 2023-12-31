//
//  CJPayRetainVoucherV3View.h
//  Aweme
//
//  Created by 尚怀军 on 2022/12/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CJPayRetainMsgModel;
@interface CJPayRetainVoucherV3View : UIView

- (void)updateWithRetainMsgModel:(CJPayRetainMsgModel *)retainMsgModel;

@end

NS_ASSUME_NONNULL_END
