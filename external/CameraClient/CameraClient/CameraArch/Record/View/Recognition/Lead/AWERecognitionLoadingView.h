//
//  AWERecognitionLoadingView.h
//  CameraClient-Pods-Aweme
//
//  Created by Bytedance on 2021/6/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// dots layout：
/// 1. Split view area(exclude tip labels) to (ROW*COLUMN) blocks
/// 2. Randomize dot center in every block
/// play loop:
/// 1. Randomize animation begin time.
///   1.1 filter animation delay time larger than X, to make sure dots not fill up the entire space
/// 2. ... under consideration
@interface AWERecognitionLoadingView : UIView
@property (nonatomic, strong, readonly) UILabel *tipTitleLabel;
@property (nonatomic, strong, readonly) UILabel *tipHintLabel;

- (instancetype)initWithFrame:(CGRect)frame hideLottie:(BOOL)hide;

- (void)play;

- (void)stop;
@end

NS_ASSUME_NONNULL_END
