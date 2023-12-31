//
//  CJPayRetainVoucherView.h
//  Pods
//
//  Created by youerwei on 2022/2/7.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayRetainMsgModel;
@interface CJPayRetainVoucherView : UIView

- (void)updateWithRetainMsgModel:(CJPayRetainMsgModel *)retainMsgModel;

@end

NS_ASSUME_NONNULL_END
