//
//  CJPayWithDrawNoticeView.h
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import <UIKit/UIKit.h>
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBaseListViewModel.h"
@class CJPayWithDrawNoticeViewModel;
NS_ASSUME_NONNULL_BEGIN

@interface CJPayWithDrawNoticeView : UIView

@property (nonatomic, readonly) UILabel *showResponseLabel;

- (void)bindViewModel:(CJPayWithDrawNoticeViewModel *)viewModel;

@end

@interface CJPayWithDrawNoticeViewModel : CJPayBaseListViewModel

@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;

//- (CGFloat)getViewHeight;

+ (CJPayWithDrawNoticeViewModel *)modelWith:(CJPayBDCreateOrderResponse *)response;

@end

NS_ASSUME_NONNULL_END
