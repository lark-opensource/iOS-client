//
//  CJPayPasswordNormalView.h
//  arkcrypto-minigame-iOS
//
//  Created by chenbocheng on 2022/4/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayVerifyPasswordViewModel;
@class CJPayFixKeyboardView;

@interface CJPayPasswordNormalView : UIView

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel isForceNormal:(BOOL)isForceNormal;

@end

NS_ASSUME_NONNULL_END
