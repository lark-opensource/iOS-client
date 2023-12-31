//
//  ACCPublishGuideView.h
//  CameraClient-Pods-Aweme
//
//  Created by shaohua yang on 12/20/20.
//

#import <UIKit/UIKit.h>

#import <CreativeKit/ACCAnimatedButton.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPublishGuideView : UIView

// 强引导
+ (void)showGuideIn:(UIView *)parentView under:(UIButton *)topView then:(NSArray<UIButton *> *)buttons dismissBlock:(dispatch_block_t)dismissBlock;

// 弱引导
+ (void)showAnimationIn:(UILabel *)label enterFrom:(NSString *)enterFrom;

@end

NS_ASSUME_NONNULL_END
