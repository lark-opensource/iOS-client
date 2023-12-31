//
//  CJPayBaseLoadingView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBaseLoadingView : UIView

@property (nonatomic, strong) UIView *loadingContainerView;
@property (nonatomic, copy) NSString *stateDescText;

- (void)startAnimating;
- (void)stopAnimating;

@end

NS_ASSUME_NONNULL_END
