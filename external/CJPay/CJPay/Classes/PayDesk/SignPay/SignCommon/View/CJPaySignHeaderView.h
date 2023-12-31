//
//  CJPaySignHeaderView.h
//  Pods
//
//  Created by wangxiaohong on 2022/9/8.
//

#import <UIKit/UIKit.h>
#import "CJPayMarketingMsgView.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayHomePageAmountView;
@interface CJPaySignHeaderView : UIView

@property (nonatomic, assign) BOOL isSignOnly; //是否是独立签约

@property (nonatomic, strong, readonly) UIImageView *titleIconImageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *descLabel;
@property (nonatomic, strong, readonly) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong, readonly) UIImageView *logoImageView;
@property (nonatomic, strong, readonly) UILabel *logoDescLabel;
@property (nonatomic, strong, readonly) UILabel *logoSubDescLabel;

@end

NS_ASSUME_NONNULL_END
