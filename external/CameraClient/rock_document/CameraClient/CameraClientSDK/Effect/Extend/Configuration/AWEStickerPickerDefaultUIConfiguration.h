//
//  AWEStickerPickerUIConfiguration.h
//  CameraClient
//
//  Created by Chipengliu on 2020/7/17.
//

#import "AWEStickerPickerUIConfigurationProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/// 抖音风格分类 UI 配置
@interface AWEStickerPickerDefaultCategoryUIConfiguration : NSObject <AWEStickerPickerCategoryUIConfigurationProtocol>

@property (nonatomic, copy) CGSize(^layoutHandler)(NSIndexPath *indexPath);

@end

/// 抖音风格道具列表 UI 配置
@interface AWEStickerPickerDefaultEffectUIConfiguration : NSObject <AWEStickerPickerEffectUIConfigurationProtocol>

@property (nonatomic, copy, nullable) void(^effectListReloadHanlder)(void);

@end

/// 抖音风格的道具面板配置
@interface AWEStickerPickerDefaultUIConfiguration : NSObject <AWEStickerPickerUIConfigurationProtocol>

@property (nonatomic, copy, nullable) void(^categoryReloadHanlder)(void);

- (instancetype)initWithCategoryUIConfig:(AWEStickerPickerDefaultCategoryUIConfiguration *)categoryUIConfig
                          effectUIConfig:(AWEStickerPickerDefaultEffectUIConfiguration *)effectUIConfig;

@end

NS_ASSUME_NONNULL_END
