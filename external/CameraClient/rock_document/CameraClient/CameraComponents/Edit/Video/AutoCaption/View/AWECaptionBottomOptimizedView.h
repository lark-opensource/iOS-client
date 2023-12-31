//
//  AWECaptionBottomOptimizedView.h
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2021/1/3.
//

#import "AWECaptionBottomView.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCAnimatedButton;

FOUNDATION_EXPORT CGFloat AWEAutoCaptionsFooterViewHeight;

@interface AWECaptionBottomOptimizedView : AWECaptionBottomView

@property (nonatomic, strong) ACCAnimatedButton *backButton;
@property (nonatomic, strong) ACCAnimatedButton *saveButton;

@property (nonatomic, strong) UILabel *styleTitle;

@end

NS_ASSUME_NONNULL_END
