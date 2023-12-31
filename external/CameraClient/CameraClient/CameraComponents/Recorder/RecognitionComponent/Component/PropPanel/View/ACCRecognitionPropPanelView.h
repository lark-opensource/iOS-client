//
//  ACCExposePropPanelView.h
//  CameraClient-Pods-Aweme
//
//  Created by yangguocheng on 2021/1/6.
//

#import <UIKit/UIKit.h>
#import "ACCRecognitionScrollPropPanelView.h"
#import "ACCExposePanGestureRecognizer.h"
#import <CreativeKit/ACCAnimatedButton.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRecognitionPropPanelView : UIView

@property (nonatomic, strong, readonly) ACCExposePanGestureRecognizer *exposePanGestureRecognizer;
@property (nonatomic, strong, readonly) ACCRecognitionScrollPropPanelView *panelView;
@property (nonatomic, strong, readonly) UIView *backgroundView;
@property (nonatomic, strong, readonly) ACCAnimatedButton *closeButton;
@property (nonatomic, strong, readonly) ACCAnimatedButton *favorButton;
@property (nonatomic, strong, readonly) ACCAnimatedButton *moreButton;

@property (nonatomic, assign) CGFloat trayViewOffset;

@property (nonatomic, assign) CGFloat recordButtonTop;

@property (nonatomic, copy) void (^closeButtonClickCallback)(void);
@property (nonatomic, copy) void (^favorButtonClickCallback)(void);
@property (nonatomic, copy) void (^moreButtonClickCallback)(void);
@property (nonatomic, copy) void (^onTrayViewChanged)(UIView * _Nullable trayView);

- (void)setFavorButtonSelected:(BOOL)isSelected;
- (void)setShowFavorAndMoreButton:(BOOL)shouldShow;

@end

NS_ASSUME_NONNULL_END
