//
//  CJPayPasswordWithOpenBioGuideView.h
//  arkcrypto-minigame-iOS
//
//  Created by chenbocheng on 2022/4/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayVerifyPasswordViewModel;

@interface CJPayPasswordWithOpenBioGuideView : UIView

@property (nonatomic, copy) void(^onConfirmClickBlock)(void);

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel;

@end

NS_ASSUME_NONNULL_END
