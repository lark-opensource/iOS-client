//
//  CJPayPasswordWithSkipPwdGuideView.h
//  arkcrypto-minigame-iOS
//
//  Created by chenbocheng on 2022/4/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayVerifyPasswordViewModel;

@interface CJPayPasswordWithSkipPwdGuideView : UIView

@property (nonatomic, copy) void(^onConfirmClickBlock)(void);
@property (nonatomic, copy) void(^protocolClickBlock)(void);

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel containerHeight:(CGFloat)containerHeight;

@end

NS_ASSUME_NONNULL_END
