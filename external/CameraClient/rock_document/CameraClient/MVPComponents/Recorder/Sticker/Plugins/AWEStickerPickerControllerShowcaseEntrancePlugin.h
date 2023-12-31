//
//  AWEStickerPickerControllerShowcaseEntrancePlugin.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangchengtao on 2020/11/18.
//

#import <Foundation/Foundation.h>
#import "AWEStickerPickerControllerPluginProtocol.h"
#import "AWEStickerViewLayoutManagerProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 熟人社交 - 道具面板增加大家都在拍
 * PRD: https://bytedance.feishu.cn/docs/doccnX3jPjcYUbSGRD1vZLyPkmc#
 * https://bits.bytedance.net/meego/aweme/story/detail/840640
 */
@interface AWEStickerPickerControllerShowcaseEntrancePlugin : NSObject <AWEStickerPickerControllerPluginProtocol>

@property (nonatomic, weak) id<AWEStickerViewLayoutManagerProtocol> layoutManager;

@property (nonatomic, copy, nullable) NSString *(^getCreationId)(void);

@end

NS_ASSUME_NONNULL_END
