//
//  AWEStickerPickerErrorView.h
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/26.
//

#import <CameraClient/AWEStickerPickerOverlayView.h>
#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 道具加载error视图：“网络不给力，请点击重试”
 */
@interface AWEStickerPickerErrorView : AWEStickerPickerOverlayView <AWEStickerPickerEffectErrorViewProtocol>

@property (nonatomic, copy) void(^reloadHanlder)(void);

@end

NS_ASSUME_NONNULL_END
