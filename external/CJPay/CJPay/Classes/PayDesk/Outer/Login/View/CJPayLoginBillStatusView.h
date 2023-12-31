//
//  CJPayLoginBillStatusView.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, CJPayLoginOrderStatus);

@interface CJPayLoginBillStatusView : UIView

- (void)showStatus:(CJPayLoginOrderStatus)loginOrderStatus msg:(nullable NSString *)msg;

@end

NS_ASSUME_NONNULL_END
