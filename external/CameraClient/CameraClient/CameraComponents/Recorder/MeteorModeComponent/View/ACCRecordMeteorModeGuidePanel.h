//
//  ACCRecordMeteorModeGuidePanel.h
//  CameraClient-Pods-Aweme
//
//  Created by Chen Long on 2021/5/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, ACCRecordMeteorModeGuidePanelDismissScene) {
    ACCRecordMeteorModeGuidePanelDismissSceneClickConfirmButton,
    ACCRecordMeteorModeGuidePanelDismissSceneClickCloseButton,
    ACCRecordMeteorModeGuidePanelDismissSceneClickMaskView,
};

@interface ACCRecordMeteorModeGuidePanel : UIView

@property (nonatomic, strong) UIView *bgView;

+ (void)showOnView:(UIView *)containerView
  withConfirmBlock:(nullable dispatch_block_t)confirmBlock
      dismissBlock:(nullable void(^)(ACCRecordMeteorModeGuidePanelDismissScene dismissScene))dismissBlock
     hasBackground:(BOOL)hasBackground;

@end

NS_ASSUME_NONNULL_END
