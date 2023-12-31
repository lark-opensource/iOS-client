//
//  CJPayLoginbillView.h
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/3.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayQueryPayOrderInfoResponse;
typedef NS_ENUM(NSInteger, CJPayLoginOrderStatus);

@interface CJPayLoginBillView : UIView

@property (nonatomic, strong, readonly) UIView *contentView;

- (void)showStatus:(CJPayLoginOrderStatus)loginOrderStatus msg:(nullable NSString *)msg;

- (void)updateLoginBillViewWithResponse:(CJPayQueryPayOrderInfoResponse *)response;

@end

NS_ASSUME_NONNULL_END
