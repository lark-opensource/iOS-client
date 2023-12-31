//
//  CJPayNoNetworkContainerView.h
//  CJPay
//
//  Created by wangxinhua on 2020/6/7.
//

#import <UIKit/UIKit.h>
#import "CJPayServerThemeStyle.h"
#import "CJPayNoNetworkView.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayNoNetworkContainerView : UIView

@property (nonatomic, copy) CJPayNoNetworkViewBlock refreshBlock;
@property (nonatomic, assign) UIEdgeInsets edgeInsets;

- (void)showStyle:(CJPayTheme)payTheme;

@end

NS_ASSUME_NONNULL_END
