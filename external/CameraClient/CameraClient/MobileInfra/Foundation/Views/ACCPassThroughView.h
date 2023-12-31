//
//  ACCPassThroughView.h
//  CameraClient
//
//  Created by liyingpeng on 2020/5/18.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCPassThroughAccessibilityDelegate <NSObject>

@optional
- (void)passThroughViewDidBecomeFocused;

@end

@interface ACCPassThroughView : UIView

@property (nonatomic, weak, nullable) id<ACCPassThroughAccessibilityDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
