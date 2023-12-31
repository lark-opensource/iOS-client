//
//  AWEStickerPickerOverlayView.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import <UIKit/UIKit.h>
#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface AWEStickerPickerOverlayView : UIView <AWEStickerPickerEffectOverlayProtocol>

- (void)showOnView:(UIView *)view;

- (void)dismiss;

@end

NS_ASSUME_NONNULL_END
