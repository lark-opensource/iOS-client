//
//  CJPayRetainVoucherListView.h
//  Pods
//
//  Created by youerwei on 2022/2/7.
//

#import <UIKit/UIKit.h>
#import "CJPayBDRetainInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayRetainMsgModel;
@interface CJPayRetainVoucherListView : UIView

- (void)updateWithRetainMsgModels:(NSArray<CJPayRetainMsgModel *> *)retainMsgModels
                     vourcherType:(CJPayRetainVoucherType)vourcherType;

@end

NS_ASSUME_NONNULL_END
