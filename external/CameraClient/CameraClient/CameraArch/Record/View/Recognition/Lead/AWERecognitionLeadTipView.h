//
//  AWERecognitionLeadTipView.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWERecognitionLeadTipView : UIView
@property (nonatomic, strong, readonly) UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *contentLabel;


/// play lottie once(contains 2 times animation)
- (void)playWithCompletion:(dispatch_block_t)completion;

/// lottie itself contains 2 times animation, so pass paramter times will play animtion 2* times
- (void)playWithTimes:(NSInteger)times completion:(dispatch_block_t)completion;
@end

NS_ASSUME_NONNULL_END
