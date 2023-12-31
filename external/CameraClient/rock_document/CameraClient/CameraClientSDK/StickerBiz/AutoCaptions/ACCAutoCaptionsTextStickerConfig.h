//
//  ACCAutoCaptionsTextStickerConfig.h
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/27.
//

#import "ACCCommonStickerConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCAutoCaptionsTextStickerConfig : ACCCommonStickerConfig

// 删除气泡事件
@property (nonatomic, copy, nullable) void (^deleteBlock)(void);
// 编辑起泡事件
@property (nonatomic, copy, nullable) void (^editBlock)(void);

@end

NS_ASSUME_NONNULL_END
