//
//  CJPayDouyinStyleLoadingView.h
//  CJPay
//
//  Created by 孔伊宁 on 2022/8/10.
//

#import <UIKit/UIKit.h>
#import "CJPayEnumUtil.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayLoadingStyleInfo;
@interface CJPayDouyinStyleLoadingView : UIView

@property (nonatomic, strong) CJPayLoadingStyleInfo *loadingStyleInfo;

+ (CJPayDouyinStyleLoadingView *)sharedView;
- (void)showLoading;
- (void)showLoadingWithTitle:(nullable NSString *)title;
- (void)setLoadingTitle:(nullable NSString *)title;
- (void)stopLoadingWithState:(CJPayLoadingQueryState)state;
- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
