//
//  ACCCutSamePlayerControlView.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCCutSamePlayerControlView : UIView

@property (nonatomic, copy) void (^tapAction)(void);

@property (nonatomic, assign) BOOL enablePauseIcon;

- (void)showPauseWithAnimated:(BOOL)animated;

- (void)hidePauseWithAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
