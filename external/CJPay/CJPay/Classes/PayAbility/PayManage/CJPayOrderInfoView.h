//
//  CJPayOrderInfoView.h
//  Pods
//
//  Created by bytedance on 2022/4/12.
//

#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@class CJPayMemBankSupportListResponse;
@interface CJPayOrderInfoView : UIView
 
- (void)updateWithText:(NSString *)text iconURL:(NSString *)URL;

@end

NS_ASSUME_NONNULL_END
