//
//  AWEStickerPickerControllerCollectionStickerPlugin.h
//  CameraClient
//
//  Created by zhangchengtao on 2019/12/25.
//

#import <Foundation/Foundation.h>
#import "AWEStickerPickerControllerPluginProtocol.h"
#import "AWEStickerViewLayoutManagerProtocol.h"
#import "ACCRecordPropService.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ACCCameraService;
/**
 * 聚合（或关联）道具插件
 */
@interface AWEStickerPickerControllerCollectionStickerPlugin : NSObject <AWEStickerPickerControllerPluginProtocol>

@property (nonatomic, weak) id<AWEStickerViewLayoutManagerProtocol> layoutManager;

@property (nonatomic, strong) IESEffectModel *currentSticker;
@property (nonatomic, strong) IESEffectModel *currentChildSticker;

@property (nonatomic, copy, nullable) NSDictionary * _Nullable(^trackingInfoDictionaryBlock)(void);

@property (nonatomic, copy, nullable) void (^didSelectStickerBlock)(IESEffectModel * _Nullable sticker, ACCRecordPropChangeReason byReason);
@property (nonatomic, copy, nullable) id<ACCCameraService>(^cameraServiceBlock)(void);

- (void)showPanelIfNeeded;

@end

NS_ASSUME_NONNULL_END
