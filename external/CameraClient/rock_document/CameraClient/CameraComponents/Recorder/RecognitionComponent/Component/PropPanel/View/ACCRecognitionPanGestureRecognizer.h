//
//  ACCExposePanGestureRecognizer.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// all touch deals will delegate With innerTouchDelegateView expect Pan Gesture
@interface ACCRecognitionPanGestureRecognizer : UIGestureRecognizer

@property (nonatomic, weak) UIView *innerTouchDelegateView;

@end

NS_ASSUME_NONNULL_END
