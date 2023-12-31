//
//  ACCRecordObscurationGuideView.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecordObscurationGuideView : UIView

+ (void)showGuideTitle:(NSString *)title description:(NSString *)description below:(UIView *)belowView;

@end

NS_ASSUME_NONNULL_END
