//
//  DVEPickerOverlayView.h
//  CameraClient
//
//  Created by bytedance on 2020/4/26.
//

#import <UIKit/UIKit.h>
#import "DVEPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEPickerOverlayView : UIView <DVEPickerEffectOverlayProtocol>

- (void)showOnView:(UIView *)view;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
