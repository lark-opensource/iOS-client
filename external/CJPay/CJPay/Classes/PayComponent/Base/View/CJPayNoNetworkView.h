//
//  CJPayNoNetworkView.h
//  CJPay
//
//  Created by wangxiaohong on 2019/11/22.
//

#import "CJPayButton.h"
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CJPayNoNetworkViewBlock)(void);

@interface CJPayNoNetworkView : UIView

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *subTitleLabel;
@property (nonatomic, strong, readonly) CJPayButton *refreshButton;

@property (nonatomic, copy) CJPayNoNetworkViewBlock refreshBlock;

@end

NS_ASSUME_NONNULL_END
